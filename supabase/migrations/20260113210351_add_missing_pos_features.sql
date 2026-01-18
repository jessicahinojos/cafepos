-- =====================================================
-- MISSING POS CRITICAL FEATURES MIGRATION
-- =====================================================
-- Module 1: Printer Integration System
-- Module 2: Barcode Scanning Enhancement
-- Module 3: Loyalty Points Automation
-- Module 4: Advanced Analytics
-- =====================================================

-- =====================================================
-- MODULE 1: PRINTER INTEGRATION SYSTEM
-- =====================================================

-- Printer types enum
CREATE TYPE printer_type AS ENUM (
    'thermal',
    'inkjet',
    'laser',
    'network'
);

-- Printer status enum
CREATE TYPE printer_status AS ENUM (
    'online',
    'offline',
    'error',
    'maintenance'
);

-- Receipt types enum
CREATE TYPE receipt_type AS ENUM (
    'sale',
    'refund',
    'kitchen',
    'customer_copy',
    'daily_summary'
);

-- Printers configuration table
CREATE TABLE printers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type printer_type NOT NULL,
    ip_address TEXT,
    port INTEGER DEFAULT 9100,
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    paper_width INTEGER DEFAULT 80, -- millimeters
    status printer_status DEFAULT 'offline',
    last_ping TIMESTAMPTZ,
    settings JSONB DEFAULT '{}', -- printer-specific settings
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Receipt templates table
CREATE TABLE receipt_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type receipt_type NOT NULL,
    header_text TEXT,
    footer_text TEXT,
    show_logo BOOLEAN DEFAULT true,
    show_qr_code BOOLEAN DEFAULT false,
    font_size INTEGER DEFAULT 12,
    template_data JSONB DEFAULT '{}', -- custom template configuration
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Print jobs queue table
CREATE TABLE print_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    printer_id UUID REFERENCES printers(id) ON DELETE SET NULL,
    template_id UUID REFERENCES receipt_templates(id) ON DELETE SET NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    type receipt_type NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, printing, completed, failed
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    print_data JSONB NOT NULL, -- complete receipt data
    printed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MODULE 2: BARCODE SCANNING ENHANCEMENTS
-- =====================================================

-- Barcode scan logs table
CREATE TABLE barcode_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode TEXT NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    user_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
    scan_type TEXT DEFAULT 'sale', -- sale, inventory, price_check
    found BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create index for fast barcode lookup
CREATE INDEX idx_products_barcode_lookup ON products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_barcode_scans_created ON barcode_scans(created_at DESC);
CREATE INDEX idx_barcode_scans_product ON barcode_scans(product_id);

-- =====================================================
-- MODULE 3: LOYALTY POINTS AUTOMATION
-- =====================================================

-- Loyalty tiers enum
CREATE TYPE loyalty_tier AS ENUM (
    'bronze',
    'silver', 
    'gold',
    'platinum'
);

-- Loyalty rules configuration table
CREATE TABLE loyalty_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    points_per_boliviano NUMERIC(10,2) DEFAULT 1.00, -- 1 Bs = X points
    min_purchase_amount NUMERIC(10,2) DEFAULT 0,
    tier loyalty_tier DEFAULT 'bronze',
    bonus_multiplier NUMERIC(3,2) DEFAULT 1.00,
    is_active BOOLEAN DEFAULT true,
    valid_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Points transactions log table
CREATE TABLE points_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    points_change INTEGER NOT NULL, -- positive for earn, negative for redeem
    transaction_type TEXT NOT NULL, -- earned, redeemed, adjusted, expired
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    notes TEXT,
    user_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Client loyalty tier tracking
ALTER TABLE clients ADD COLUMN IF NOT EXISTS loyalty_tier loyalty_tier DEFAULT 'bronze';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS points_earned_lifetime INTEGER DEFAULT 0;

-- =====================================================
-- MODULE 4: ADVANCED ANALYTICS
-- =====================================================

-- Product performance metrics table
CREATE TABLE product_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    units_sold INTEGER DEFAULT 0,
    revenue NUMERIC(10,2) DEFAULT 0,
    profit NUMERIC(10,2) DEFAULT 0,
    avg_preparation_time INTEGER, -- seconds
    refund_count INTEGER DEFAULT 0,
    rating_avg NUMERIC(3,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, date)
);

-- Staff performance metrics table
CREATE TABLE staff_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    orders_processed INTEGER DEFAULT 0,
    total_sales NUMERIC(10,2) DEFAULT 0,
    avg_order_time INTEGER, -- seconds
    customer_rating NUMERIC(3,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);

-- Hourly sales analytics table
CREATE TABLE hourly_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
    orders_count INTEGER DEFAULT 0,
    revenue NUMERIC(10,2) DEFAULT 0,
    avg_order_value NUMERIC(10,2) DEFAULT 0,
    unique_customers INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date, hour)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Printer indexes
CREATE INDEX idx_printers_status ON printers(status) WHERE is_active = true;
CREATE INDEX idx_printers_default ON printers(is_default) WHERE is_active = true;

-- Print jobs indexes
CREATE INDEX idx_print_jobs_status ON print_jobs(status, created_at DESC);
CREATE INDEX idx_print_jobs_printer ON print_jobs(printer_id) WHERE status != 'completed';
CREATE INDEX idx_print_jobs_order ON print_jobs(order_id);

-- Receipt templates indexes
CREATE INDEX idx_receipt_templates_type ON receipt_templates(type) WHERE is_active = true;
CREATE INDEX idx_receipt_templates_default ON receipt_templates(is_default, type);

-- Points transactions indexes
CREATE INDEX idx_points_transactions_client ON points_transactions(client_id, created_at DESC);
CREATE INDEX idx_points_transactions_order ON points_transactions(order_id);

-- Analytics indexes
CREATE INDEX idx_product_analytics_date ON product_analytics(date DESC);
CREATE INDEX idx_product_analytics_product ON product_analytics(product_id);
CREATE INDEX idx_staff_analytics_date ON staff_analytics(date DESC);
CREATE INDEX idx_staff_analytics_user ON staff_analytics(user_id);
CREATE INDEX idx_hourly_analytics_date ON hourly_analytics(date DESC, hour);

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE printers ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE print_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE barcode_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE hourly_analytics ENABLE ROW LEVEL SECURITY;

-- Printers policies
CREATE POLICY "authenticated_manage_printers" ON printers FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Receipt templates policies
CREATE POLICY "authenticated_manage_templates" ON receipt_templates FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Print jobs policies
CREATE POLICY "authenticated_manage_print_jobs" ON print_jobs FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Barcode scans policies
CREATE POLICY "authenticated_log_scans" ON barcode_scans FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "authenticated_view_scans" ON barcode_scans FOR SELECT TO authenticated USING (true);

-- Loyalty rules policies
CREATE POLICY "authenticated_view_loyalty_rules" ON loyalty_rules FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin_manage_loyalty_rules" ON loyalty_rules FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
) WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
);

-- Points transactions policies
CREATE POLICY "authenticated_view_points" ON points_transactions FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_manage_points" ON points_transactions FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Analytics policies (read-only for most staff)
CREATE POLICY "staff_view_product_analytics" ON product_analytics FOR SELECT TO authenticated USING (true);
CREATE POLICY "managers_manage_product_analytics" ON product_analytics FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
) WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
);

CREATE POLICY "staff_view_own_analytics" ON staff_analytics FOR SELECT TO authenticated USING (
    user_id = auth.uid() OR 
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
);

CREATE POLICY "managers_manage_staff_analytics" ON staff_analytics FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
) WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
);

CREATE POLICY "staff_view_hourly_analytics" ON hourly_analytics FOR SELECT TO authenticated USING (true);
CREATE POLICY "managers_manage_hourly_analytics" ON hourly_analytics FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
) WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to automatically calculate loyalty points
CREATE OR REPLACE FUNCTION calculate_loyalty_points(
    p_client_id UUID,
    p_order_total NUMERIC,
    p_order_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_points INTEGER;
    v_rule RECORD;
    v_current_balance INTEGER;
    v_tier loyalty_tier;
BEGIN
    -- Get client current points and tier
    SELECT loyalty_points, loyalty_tier INTO v_current_balance, v_tier
    FROM clients WHERE id = p_client_id;
    
    -- Get applicable loyalty rule
    SELECT * INTO v_rule FROM loyalty_rules
    WHERE is_active = true 
    AND tier = v_tier
    AND (valid_until IS NULL OR valid_until > CURRENT_TIMESTAMP)
    AND p_order_total >= min_purchase_amount
    ORDER BY bonus_multiplier DESC
    LIMIT 1;
    
    IF v_rule IS NULL THEN
        v_points := FLOOR(p_order_total); -- Default 1 point per Bs
    ELSE
        v_points := FLOOR(p_order_total * v_rule.points_per_boliviano * v_rule.bonus_multiplier);
    END IF;
    
    -- Insert points transaction
    INSERT INTO points_transactions (
        client_id, order_id, points_change, transaction_type,
        balance_before, balance_after
    ) VALUES (
        p_client_id, p_order_id, v_points, 'earned',
        v_current_balance, v_current_balance + v_points
    );
    
    -- Update client points
    UPDATE clients 
    SET loyalty_points = loyalty_points + v_points,
        points_earned_lifetime = points_earned_lifetime + v_points
    WHERE id = p_client_id;
    
    RETURN v_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-calculate points when order is completed
CREATE OR REPLACE FUNCTION trigger_calculate_points()
RETURNS TRIGGER AS $$
BEGIN
    -- Only calculate points when order is completed and has a client
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' 
       AND NEW.client_id IS NOT NULL AND NEW.total > 0 THEN
        PERFORM calculate_loyalty_points(NEW.client_id, NEW.total, NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_points_calculation
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calculate_points();

-- Function to update loyalty tier based on lifetime points
CREATE OR REPLACE FUNCTION update_loyalty_tier()
RETURNS TRIGGER AS $$
BEGIN
    -- Update tier based on lifetime points earned
    NEW.loyalty_tier := CASE
        WHEN NEW.points_earned_lifetime >= 10000 THEN 'platinum'::loyalty_tier
        WHEN NEW.points_earned_lifetime >= 5000 THEN 'gold'::loyalty_tier
        WHEN NEW.points_earned_lifetime >= 2000 THEN 'silver'::loyalty_tier
        ELSE 'bronze'::loyalty_tier
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER client_tier_update
    BEFORE UPDATE ON clients
    FOR EACH ROW
    WHEN (OLD.points_earned_lifetime IS DISTINCT FROM NEW.points_earned_lifetime)
    EXECUTE FUNCTION update_loyalty_tier();

-- Function to create daily analytics aggregation
CREATE OR REPLACE FUNCTION aggregate_daily_analytics()
RETURNS void AS $$
DECLARE
    v_date DATE := CURRENT_DATE - INTERVAL '1 day';
BEGIN
    -- Aggregate product analytics
    INSERT INTO product_analytics (product_id, date, units_sold, revenue, profit)
    SELECT 
        oi.product_id,
        v_date,
        SUM(oi.quantity) as units_sold,
        SUM(oi.subtotal) as revenue,
        SUM(oi.subtotal - (p.cost * oi.quantity)) as profit
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    JOIN products p ON oi.product_id = p.id
    WHERE DATE(o.created_at) = v_date
    AND o.status = 'delivered'
    GROUP BY oi.product_id
    ON CONFLICT (product_id, date) DO UPDATE
    SET units_sold = EXCLUDED.units_sold,
        revenue = EXCLUDED.revenue,
        profit = EXCLUDED.profit;
    
    -- Aggregate staff analytics
    INSERT INTO staff_analytics (user_id, date, orders_processed, total_sales)
    SELECT 
        o.user_id,
        v_date,
        COUNT(*) as orders_processed,
        SUM(o.total) as total_sales
    FROM orders o
    WHERE DATE(o.created_at) = v_date
    AND o.status = 'delivered'
    GROUP BY o.user_id
    ON CONFLICT (user_id, date) DO UPDATE
    SET orders_processed = EXCLUDED.orders_processed,
        total_sales = EXCLUDED.total_sales;
    
    -- Aggregate hourly analytics
    INSERT INTO hourly_analytics (date, hour, orders_count, revenue, avg_order_value, unique_customers)
    SELECT 
        v_date,
        EXTRACT(HOUR FROM o.created_at)::INTEGER as hour,
        COUNT(*) as orders_count,
        SUM(o.total) as revenue,
        AVG(o.total) as avg_order_value,
        COUNT(DISTINCT o.client_id) FILTER (WHERE o.client_id IS NOT NULL) as unique_customers
    FROM orders o
    WHERE DATE(o.created_at) = v_date
    AND o.status = 'delivered'
    GROUP BY hour
    ON CONFLICT (date, hour) DO UPDATE
    SET orders_count = EXCLUDED.orders_count,
        revenue = EXCLUDED.revenue,
        avg_order_value = EXCLUDED.avg_order_value,
        unique_customers = EXCLUDED.unique_customers;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to log barcode scans and track product not found
CREATE OR REPLACE FUNCTION log_barcode_scan(
    p_barcode TEXT,
    p_user_id UUID DEFAULT NULL,
    p_scan_type TEXT DEFAULT 'sale'
) RETURNS JSON AS $$
DECLARE
    v_product RECORD;
    v_found BOOLEAN;
    v_result JSON;
BEGIN
    -- Look up product by barcode
    SELECT id, name, price, is_available INTO v_product
    FROM products
    WHERE barcode = p_barcode AND is_active = true;
    
    v_found := FOUND;
    
    -- Log the scan
    INSERT INTO barcode_scans (barcode, product_id, user_id, scan_type, found)
    VALUES (p_barcode, v_product.id, p_user_id, p_scan_type, v_found);
    
    -- Return result
    IF v_found THEN
        v_result := json_build_object(
            'found', true,
            'product', json_build_object(
                'id', v_product.id,
                'name', v_product.name,
                'price', v_product.price,
                'available', v_product.is_available
            )
        );
    ELSE
        v_result := json_build_object(
            'found', false,
            'message', 'Producto no encontrado con código: ' || p_barcode
        );
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Updated timestamp triggers for new tables
CREATE TRIGGER update_printers_updated_at BEFORE UPDATE ON printers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_receipt_templates_updated_at BEFORE UPDATE ON receipt_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_loyalty_rules_updated_at BEFORE UPDATE ON loyalty_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- SAMPLE DATA FOR NEW FEATURES
-- =====================================================

-- Insert default printer configuration
INSERT INTO printers (name, type, is_default, is_active, status) VALUES
('Impresora Principal', 'thermal', true, true, 'online'),
('Cocina', 'thermal', false, true, 'online');

-- Insert default receipt templates
INSERT INTO receipt_templates (name, type, header_text, footer_text, is_default) VALUES
('Recibo Venta Estándar', 'sale', 
 'CAFÉ POS\nNIT: 123456789\nTel: +591 12345678', 
 'Gracias por su preferencia\n¡Vuelva pronto!', 
 true),
('Orden Cocina', 'kitchen',
 'ORDEN COCINA',
 'Preparar inmediatamente',
 true);

-- Insert default loyalty rule
INSERT INTO loyalty_rules (name, points_per_boliviano, tier, bonus_multiplier) VALUES
('Regla Estándar Bronze', 1.00, 'bronze', 1.00),
('Regla Silver', 1.00, 'silver', 1.25),
('Regla Gold', 1.00, 'gold', 1.50),
('Regla Platinum', 1.00, 'platinum', 2.00);