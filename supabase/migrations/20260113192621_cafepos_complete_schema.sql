-- Location: supabase/migrations/20260113192621_cafepos_complete_schema.sql
-- Schema Analysis: Fresh POS system database creation
-- Integration Type: Complete new schema for point of sale system
-- Dependencies: None (fresh start)

-- ============================================================================
-- 1. CUSTOM TYPES
-- ============================================================================

CREATE TYPE public.user_role AS ENUM ('admin', 'manager', 'cashier', 'kitchen', 'waiter');
CREATE TYPE public.order_status AS ENUM ('pending', 'preparing', 'ready', 'delivered', 'cancelled');
CREATE TYPE public.payment_method AS ENUM ('cash', 'card', 'qr', 'transfer');
CREATE TYPE public.movement_type AS ENUM ('purchase', 'sale', 'adjustment', 'waste', 'transfer');
CREATE TYPE public.transaction_type AS ENUM ('opening', 'closing', 'withdrawal', 'deposit');

-- ============================================================================
-- 2. CORE TABLES (NO FOREIGN KEYS)
-- ============================================================================

-- User profiles table (intermediary for auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'cashier'::public.user_role,
    phone TEXT,
    is_active BOOLEAN DEFAULT true,
    pin_code TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    icon TEXT DEFAULT 'restaurant',
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Ingredients/Supplies table
CREATE TABLE public.ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    current_stock DECIMAL(10,2) DEFAULT 0,
    min_stock DECIMAL(10,2) DEFAULT 0,
    max_stock DECIMAL(10,2),
    unit_cost DECIMAL(10,2) DEFAULT 0,
    supplier TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Clients/Customers table
CREATE TABLE public.clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    loyalty_points INTEGER DEFAULT 0,
    total_purchases DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. DEPENDENT TABLES (WITH FOREIGN KEYS)
-- ============================================================================

-- Products table
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2) DEFAULT 0,
    image_url TEXT,
    barcode TEXT,
    sku TEXT,
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true,
    preparation_time INTEGER DEFAULT 0,
    calories INTEGER,
    allergens TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Recipe ingredients (junction table)
CREATE TABLE public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES public.ingredients(id) ON DELETE CASCADE,
    quantity DECIMAL(10,2) NOT NULL,
    unit TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Cash sessions table
CREATE TABLE public.cash_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    opening_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    closing_amount DECIMAL(10,2),
    expected_amount DECIMAL(10,2),
    difference DECIMAL(10,2),
    total_sales DECIMAL(10,2) DEFAULT 0,
    total_cash DECIMAL(10,2) DEFAULT 0,
    total_card DECIMAL(10,2) DEFAULT 0,
    total_qr DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    opened_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true
);

-- Orders table
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
    cash_session_id UUID REFERENCES public.cash_sessions(id) ON DELETE SET NULL,
    status public.order_status DEFAULT 'pending'::public.order_status,
    table_number TEXT,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax DECIMAL(10,2) DEFAULT 0,
    discount DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ
);

-- Order items table
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Payments table
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    cash_session_id UUID REFERENCES public.cash_sessions(id) ON DELETE SET NULL,
    method public.payment_method NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reference_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Inventory movements table
CREATE TABLE public.inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ingredient_id UUID REFERENCES public.ingredients(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    type public.movement_type NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    reference_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Cash transactions table
CREATE TABLE public.cash_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_session_id UUID REFERENCES public.cash_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    type public.transaction_type NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. INDEXES
-- ============================================================================

-- User profiles indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);

-- Categories indexes
CREATE INDEX idx_categories_is_active ON public.categories(is_active);

-- Products indexes
CREATE INDEX idx_products_category_id ON public.products(category_id);
CREATE INDEX idx_products_is_active ON public.products(is_active);
CREATE INDEX idx_products_name ON public.products(name);
CREATE INDEX idx_products_barcode ON public.products(barcode);

-- Recipes indexes
CREATE INDEX idx_recipes_product_id ON public.recipes(product_id);
CREATE INDEX idx_recipes_ingredient_id ON public.recipes(ingredient_id);

-- Ingredients indexes
CREATE INDEX idx_ingredients_is_active ON public.ingredients(is_active);
CREATE INDEX idx_ingredients_current_stock ON public.ingredients(current_stock);

-- Clients indexes
CREATE INDEX idx_clients_phone ON public.clients(phone);
CREATE INDEX idx_clients_is_active ON public.clients(is_active);

-- Orders indexes
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_client_id ON public.orders(client_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at);
CREATE INDEX idx_orders_order_number ON public.orders(order_number);

-- Order items indexes
CREATE INDEX idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX idx_order_items_product_id ON public.order_items(product_id);

-- Payments indexes
CREATE INDEX idx_payments_order_id ON public.payments(order_id);
CREATE INDEX idx_payments_cash_session_id ON public.payments(cash_session_id);
CREATE INDEX idx_payments_created_at ON public.payments(created_at);

-- Cash sessions indexes
CREATE INDEX idx_cash_sessions_user_id ON public.cash_sessions(user_id);
CREATE INDEX idx_cash_sessions_is_active ON public.cash_sessions(is_active);
CREATE INDEX idx_cash_sessions_opened_at ON public.cash_sessions(opened_at);

-- Inventory movements indexes
CREATE INDEX idx_inventory_movements_ingredient_id ON public.inventory_movements(ingredient_id);
CREATE INDEX idx_inventory_movements_type ON public.inventory_movements(type);
CREATE INDEX idx_inventory_movements_created_at ON public.inventory_movements(created_at);

-- Cash transactions indexes
CREATE INDEX idx_cash_transactions_cash_session_id ON public.cash_transactions(cash_session_id);
CREATE INDEX idx_cash_transactions_type ON public.cash_transactions(type);

-- ============================================================================
-- 5. FUNCTIONS (MUST BE BEFORE RLS POLICIES)
-- ============================================================================

-- Function to generate order number
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_number TEXT;
    date_prefix TEXT;
    sequence_num INTEGER;
BEGIN
    date_prefix := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 10) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM public.orders
    WHERE order_number LIKE date_prefix || '%';
    
    new_number := date_prefix || '-' || LPAD(sequence_num::TEXT, 4, '0');
    
    RETURN new_number;
END;
$$;

-- Function to update product stock after order
CREATE OR REPLACE FUNCTION public.update_stock_after_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.status = 'delivered'::public.order_status AND 
       (OLD.status IS NULL OR OLD.status != 'delivered'::public.order_status) THEN
        
        UPDATE public.ingredients i
        SET current_stock = i.current_stock - (r.quantity * oi.quantity)
        FROM public.order_items oi
        JOIN public.recipes r ON r.product_id = oi.product_id
        WHERE oi.order_id = NEW.id
        AND r.ingredient_id = i.id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Function for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role, phone)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'cashier'::public.user_role),
        NEW.raw_user_meta_data->>'phone'
    );
    RETURN NEW;
END;
$$;

-- ============================================================================
-- 6. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_transactions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 7. RLS POLICIES (AFTER FUNCTIONS)
-- ============================================================================

-- User profiles policies (Pattern 1: Core user table)
CREATE POLICY "users_manage_own_profile"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Categories policies (Pattern 4: Public read, authenticated write)
CREATE POLICY "public_can_read_categories"
ON public.categories
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "authenticated_can_manage_categories"
ON public.categories
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Products policies (Pattern 4: Public read, authenticated write)
CREATE POLICY "public_can_read_products"
ON public.products
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "authenticated_can_manage_products"
ON public.products
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Recipes policies
CREATE POLICY "authenticated_can_manage_recipes"
ON public.recipes
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Ingredients policies
CREATE POLICY "authenticated_can_manage_ingredients"
ON public.ingredients
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Clients policies
CREATE POLICY "authenticated_can_manage_clients"
ON public.clients
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Orders policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_orders"
ON public.orders
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Order items policies
CREATE POLICY "users_manage_order_items"
ON public.order_items
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_items.order_id
        AND o.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_items.order_id
        AND o.user_id = auth.uid()
    )
);

-- Payments policies
CREATE POLICY "users_manage_payments"
ON public.payments
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = payments.order_id
        AND o.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = payments.order_id
        AND o.user_id = auth.uid()
    )
);

-- Cash sessions policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_cash_sessions"
ON public.cash_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Inventory movements policies
CREATE POLICY "authenticated_can_manage_inventory"
ON public.inventory_movements
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Cash transactions policies
CREATE POLICY "users_manage_cash_transactions"
ON public.cash_transactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 8. TRIGGERS
-- ============================================================================

-- Trigger for automatic user profile creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Triggers for updated_at timestamps
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_ingredients_updated_at
    BEFORE UPDATE ON public.ingredients
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_clients_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Trigger for stock management
CREATE TRIGGER update_stock_on_order_completion
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.update_stock_after_order();

-- ============================================================================
-- 9. MOCK DATA
-- ============================================================================

DO $$
DECLARE
    admin_id UUID := gen_random_uuid();
    cashier_id UUID := gen_random_uuid();
    kitchen_id UUID := gen_random_uuid();
    
    cat_bebidas UUID := gen_random_uuid();
    cat_comidas UUID := gen_random_uuid();
    cat_postres UUID := gen_random_uuid();
    
    prod_cafe UUID := gen_random_uuid();
    prod_hamburguesa UUID := gen_random_uuid();
    prod_helado UUID := gen_random_uuid();
    
    ing_cafe UUID := gen_random_uuid();
    ing_leche UUID := gen_random_uuid();
    ing_carne UUID := gen_random_uuid();
    
    client1_id UUID := gen_random_uuid();
    client2_id UUID := gen_random_uuid();
    
    session_id UUID := gen_random_uuid();
    order1_id UUID := gen_random_uuid();
BEGIN
    -- Insert auth users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@cafepos.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin Usuario", "role": "admin", "phone": "70123456"}'::jsonb,
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (cashier_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'cajero@cafepos.com', crypt('cajero123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Cajero Usuario", "role": "cashier", "phone": "71234567"}'::jsonb,
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (kitchen_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'cocina@cafepos.com', crypt('cocina123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Cocina Usuario", "role": "kitchen", "phone": "72345678"}'::jsonb,
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Insert categories
    INSERT INTO public.categories (id, name, description, color, icon, display_order) VALUES
        (cat_bebidas, 'Bebidas', 'Bebidas calientes y frías', '#3B82F6', 'local_cafe', 1),
        (cat_comidas, 'Comidas', 'Platos principales', '#F59E0B', 'restaurant', 2),
        (cat_postres, 'Postres', 'Postres y dulces', '#EC4899', 'cake', 3);

    -- Insert ingredients
    INSERT INTO public.ingredients (id, name, unit, current_stock, min_stock, unit_cost) VALUES
        (ing_cafe, 'Café en grano', 'kg', 25.0, 5.0, 45.0),
        (ing_leche, 'Leche', 'litro', 30.0, 10.0, 8.0),
        (ing_carne, 'Carne molida', 'kg', 15.0, 5.0, 35.0);

    -- Insert products
    INSERT INTO public.products (id, category_id, name, description, price, cost, preparation_time) VALUES
        (prod_cafe, cat_bebidas, 'Café Americano', 'Café negro recién preparado', 15.0, 5.0, 5),
        (prod_hamburguesa, cat_comidas, 'Hamburguesa Clásica', 'Hamburguesa con queso y vegetales', 45.0, 20.0, 15),
        (prod_helado, cat_postres, 'Helado de Chocolate', 'Helado artesanal', 20.0, 8.0, 2);

    -- Insert recipes
    INSERT INTO public.recipes (product_id, ingredient_id, quantity, unit) VALUES
        (prod_cafe, ing_cafe, 0.02, 'kg'),
        (prod_cafe, ing_leche, 0.05, 'litro'),
        (prod_hamburguesa, ing_carne, 0.15, 'kg');

    -- Insert clients
    INSERT INTO public.clients (id, name, phone, loyalty_points) VALUES
        (client1_id, 'Juan Pérez', '71234567', 150),
        (client2_id, 'María García', '72345678', 75);

    -- Insert cash session
    INSERT INTO public.cash_sessions (id, user_id, opening_amount, is_active, opened_at) VALUES
        (session_id, cashier_id, 200.0, true, now());

    -- Insert orders
    INSERT INTO public.orders (
        id, order_number, user_id, client_id, cash_session_id, 
        status, subtotal, tax, total, created_at
    ) VALUES
        (order1_id, '20260113-0001', cashier_id, client1_id, session_id,
         'delivered'::public.order_status, 60.0, 7.8, 67.8, now() - interval '2 hours');

    -- Insert order items
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, unit_price, subtotal) VALUES
        (order1_id, prod_cafe, 'Café Americano', 2, 15.0, 30.0),
        (order1_id, prod_hamburguesa, 'Hamburguesa Clásica', 1, 45.0, 45.0);

    -- Insert payment
    INSERT INTO public.payments (order_id, cash_session_id, method, amount) VALUES
        (order1_id, session_id, 'cash'::public.payment_method, 67.8);

END $$;