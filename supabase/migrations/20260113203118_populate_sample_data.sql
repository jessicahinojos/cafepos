-- =====================================================
-- COMPREHENSIVE POS SYSTEM DATA POPULATION (FIXED v2)
-- Migration: 20260113203118_populate_sample_data.sql
-- Purpose: Fill all POS modules with realistic test data
-- =====================================================

-- =====================================================
-- 0. ADD MISSING UNIQUE CONSTRAINTS (Required for ON CONFLICT)
-- =====================================================

-- Add unique constraint to categories.name if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'categories_name_key'
    ) THEN
        ALTER TABLE public.categories ADD CONSTRAINT categories_name_key UNIQUE (name);
    END IF;
END $$;

-- Add unique constraint to products.sku if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'products_sku_key'
    ) THEN
        ALTER TABLE public.products ADD CONSTRAINT products_sku_key UNIQUE (sku);
    END IF;
END $$;

-- Add unique constraint to ingredients.name if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'ingredients_name_key'
    ) THEN
        ALTER TABLE public.ingredients ADD CONSTRAINT ingredients_name_key UNIQUE (name);
    END IF;
END $$;

-- Add unique constraint to recipes (product_id, ingredient_id) combination
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'recipes_product_ingredient_key'
    ) THEN
        ALTER TABLE public.recipes ADD CONSTRAINT recipes_product_ingredient_key UNIQUE (product_id, ingredient_id);
    END IF;
END $$;

-- Add unique constraint to clients.phone
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'clients_phone_key'
    ) THEN
        ALTER TABLE public.clients ADD CONSTRAINT clients_phone_key UNIQUE (phone);
    END IF;
END $$;

-- =====================================================
-- 1. CATEGORIES (Product Management)
-- =====================================================
INSERT INTO categories (name, description, icon, color, display_order, is_active) VALUES
('Postres', 'Postres y dulces', 'cake', '#EC4899', 3, true),
('Ensaladas', 'Ensaladas frescas y saludables', 'eco', '#10B981', 4, true),
('Snacks', 'Bocadillos y aperitivos', 'fastfood', '#F59E0B', 5, true),
('Jugos y Batidos', 'Bebidas naturales', 'local_drink', '#8B5CF6', 6, true)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- 2. INGREDIENTS (Add ALL ingredients needed for recipes)
-- =====================================================
INSERT INTO ingredients (name, unit, unit_cost, current_stock, min_stock, max_stock, supplier, is_active) VALUES
-- Bebidas ingredients (needed for recipes)
('Azúcar', 'kg', 12, 50, 10, 100, 'Proveedor Central', true),
('Té negro', 'kg', 85, 15, 5, 30, 'Importadora Té', true),
('Chocolate en polvo', 'kg', 95, 20, 8, 40, 'Distribuidora Chocolates', true),
('Crema para batir', 'litro', 35, 25, 10, 50, 'Lácteos del Valle', true),

-- Comidas ingredients (needed for recipes)
('Pan para sándwich', 'paquete', 18, 40, 15, 80, 'Panadería Local', true),
('Pechuga de pollo', 'kg', 68, 30, 10, 60, 'Avícola Regional', true),
('Queso mozzarella', 'kg', 85, 25, 8, 50, 'Lácteos Premium', true),
('Harina para pizza', 'kg', 22, 60, 20, 100, 'Molino San José', true),
('Pepperoni', 'kg', 120, 15, 5, 30, 'Embutidos La Especial', true),
('Carne de res', 'kg', 110, 35, 12, 70, 'Carnes Premium', true),
('Tortillas', 'paquete', 15, 50, 20, 100, 'Tortillería Tradicional', true),

-- Postres ingredients (needed for recipes)
('Harina', 'kg', 18, 80, 25, 150, 'Molino San José', true),
('Huevos', 'pieza', 3.5, 200, 50, 400, 'Granja Avícola', true),
('Mantequilla', 'kg', 95, 30, 10, 60, 'Lácteos Premium', true),
('Helado base', 'litro', 65, 40, 15, 80, 'Heladería Industrial', true),

-- Ensaladas ingredients (needed for recipes)
('Lechuga', 'kg', 18, 25, 8, 50, 'Verduras Frescas', true),
('Tomate', 'kg', 22, 35, 10, 70, 'Verduras Frescas', true),
('Aderezo césar', 'litro', 55, 20, 8, 40, 'Salsas y Aderezos', true),
('Frutas mixtas', 'kg', 45, 30, 10, 60, 'Frutería Central', true),

-- Snacks ingredients (needed for recipes)
('Papas', 'kg', 15, 60, 20, 120, 'Verduras Frescas', true),
('Chips de maíz', 'kg', 35, 40, 15, 80, 'Botanas del Norte', true),
('Queso amarillo', 'kg', 75, 25, 10, 50, 'Lácteos del Valle', true),

-- Jugos ingredients (needed for recipes)
('Naranjas', 'kg', 25, 50, 15, 100, 'Frutería Central', true),
('Fresas', 'kg', 55, 30, 10, 60, 'Frutería Central', true)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- 3. PRODUCTS (with recipes and inventory)
-- =====================================================
INSERT INTO products (name, description, price, cost, category_id, sku, barcode, preparation_time, calories, allergens, is_active, is_available) VALUES
-- Bebidas
('Café Latte', 'Café con leche espumosa', 18, 6, (SELECT id FROM categories WHERE name = 'Bebidas' LIMIT 1), 'BEB-LAT-001', '7501234567890', 7, 150, ARRAY['leche'], true, true),
('Té Helado', 'Té negro helado con limón', 12, 3, (SELECT id FROM categories WHERE name = 'Bebidas' LIMIT 1), 'BEB-TEH-002', '7501234567891', 3, 80, NULL, true, true),
('Chocolate Caliente', 'Chocolate con leche y crema', 22, 8, (SELECT id FROM categories WHERE name = 'Bebidas' LIMIT 1), 'BEB-CHO-003', '7501234567892', 8, 250, ARRAY['leche', 'soya'], true, true),

-- Comidas
('Sándwich de Pollo', 'Sándwich con pollo y vegetales', 35, 15, (SELECT id FROM categories WHERE name = 'Comidas' LIMIT 1), 'COM-SAN-001', '7501234567893', 12, 420, ARRAY['gluten', 'huevo'], true, true),
('Pizza Personal', 'Pizza individual con queso y pepperoni', 55, 25, (SELECT id FROM categories WHERE name = 'Comidas' LIMIT 1), 'COM-PIZ-002', '7501234567894', 20, 650, ARRAY['gluten', 'leche'], true, true),
('Tacos de Carne', 'Tres tacos con carne asada', 42, 18, (SELECT id FROM categories WHERE name = 'Comidas' LIMIT 1), 'COM-TAC-003', '7501234567895', 15, 480, NULL, true, true),

-- Postres
('Pastel de Chocolate', 'Porción de pastel de chocolate', 28, 10, (SELECT id FROM categories WHERE name = 'Postres' LIMIT 1), 'POS-PAS-001', '7501234567896', 5, 380, ARRAY['gluten', 'leche', 'huevo'], true, true),
('Helado', 'Bola de helado sabor a elegir', 15, 5, (SELECT id FROM categories WHERE name = 'Postres' LIMIT 1), 'POS-HEL-002', '7501234567897', 2, 200, ARRAY['leche'], true, true),
('Churros', 'Orden de churros con azúcar', 20, 7, (SELECT id FROM categories WHERE name = 'Postres' LIMIT 1), 'POS-CHU-003', '7501234567898', 8, 320, ARRAY['gluten'], true, true),

-- Ensaladas
('Ensalada César', 'Ensalada con aderezo césar y crutones', 32, 12, (SELECT id FROM categories WHERE name = 'Ensaladas' LIMIT 1), 'ENS-CES-001', '7501234567899', 10, 280, ARRAY['gluten', 'huevo'], true, true),
('Ensalada Tropical', 'Mix de frutas frescas', 25, 10, (SELECT id FROM categories WHERE name = 'Ensaladas' LIMIT 1), 'ENS-TRO-002', '7501234567900', 7, 150, NULL, true, true),

-- Snacks
('Papas Fritas', 'Porción de papas fritas crujientes', 18, 6, (SELECT id FROM categories WHERE name = 'Snacks' LIMIT 1), 'SNA-PAP-001', '7501234567901', 8, 350, NULL, true, true),
('Nachos', 'Nachos con queso y jalapeños', 24, 8, (SELECT id FROM categories WHERE name = 'Snacks' LIMIT 1), 'SNA-NAC-002', '7501234567902', 10, 420, ARRAY['leche'], true, true),

-- Jugos y Batidos
('Jugo de Naranja', 'Jugo natural de naranja', 14, 4, (SELECT id FROM categories WHERE name = 'Jugos y Batidos' LIMIT 1), 'JUG-NAR-001', '7501234567903', 5, 110, NULL, true, true),
('Batido de Fresa', 'Batido cremoso de fresa', 20, 7, (SELECT id FROM categories WHERE name = 'Jugos y Batidos' LIMIT 1), 'JUG-BAT-002', '7501234567904', 6, 180, ARRAY['leche'], true, true)
ON CONFLICT (sku) DO NOTHING;

-- =====================================================
-- 4. RECIPES (Product-Ingredient relationships)
-- =====================================================
-- Café Latte (uses base ingredients from initial migration)
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-LAT-001'),
    (SELECT id FROM ingredients WHERE name = 'Café en grano'),
    0.025,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-LAT-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Café en grano')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-LAT-001'),
    (SELECT id FROM ingredients WHERE name = 'Leche'),
    0.15,
    'litro'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-LAT-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Leche')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-LAT-001'),
    (SELECT id FROM ingredients WHERE name = 'Azúcar'),
    0.01,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-LAT-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Azúcar')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Té Helado
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-TEH-002'),
    (SELECT id FROM ingredients WHERE name = 'Té negro'),
    0.01,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-TEH-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Té negro')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-TEH-002'),
    (SELECT id FROM ingredients WHERE name = 'Azúcar'),
    0.015,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-TEH-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Azúcar')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Chocolate Caliente
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-CHO-003'),
    (SELECT id FROM ingredients WHERE name = 'Chocolate en polvo'),
    0.04,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-CHO-003')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Chocolate en polvo')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-CHO-003'),
    (SELECT id FROM ingredients WHERE name = 'Leche'),
    0.2,
    'litro'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-CHO-003')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Leche')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'BEB-CHO-003'),
    (SELECT id FROM ingredients WHERE name = 'Crema para batir'),
    0.03,
    'litro'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'BEB-CHO-003')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Crema para batir')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Sándwich de Pollo
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-SAN-001'),
    (SELECT id FROM ingredients WHERE name = 'Pan para sándwich'),
    0.1,
    'paquete'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-SAN-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Pan para sándwich')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-SAN-001'),
    (SELECT id FROM ingredients WHERE name = 'Pechuga de pollo'),
    0.15,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-SAN-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Pechuga de pollo')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-SAN-001'),
    (SELECT id FROM ingredients WHERE name = 'Lechuga'),
    0.05,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-SAN-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Lechuga')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-SAN-001'),
    (SELECT id FROM ingredients WHERE name = 'Tomate'),
    0.05,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-SAN-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Tomate')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Pizza Personal
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-PIZ-002'),
    (SELECT id FROM ingredients WHERE name = 'Harina para pizza'),
    0.15,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-PIZ-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Harina para pizza')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-PIZ-002'),
    (SELECT id FROM ingredients WHERE name = 'Queso mozzarella'),
    0.1,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-PIZ-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Queso mozzarella')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-PIZ-002'),
    (SELECT id FROM ingredients WHERE name = 'Pepperoni'),
    0.05,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-PIZ-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Pepperoni')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-PIZ-002'),
    (SELECT id FROM ingredients WHERE name = 'Tomate'),
    0.08,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-PIZ-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Tomate')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Tacos de Carne
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-TAC-003'),
    (SELECT id FROM ingredients WHERE name = 'Tortillas'),
    0.15,
    'paquete'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-TAC-003')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Tortillas')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'COM-TAC-003'),
    (SELECT id FROM ingredients WHERE name = 'Carne de res'),
    0.15,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'COM-TAC-003')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Carne de res')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Pastel de Chocolate
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'POS-PAS-001'),
    (SELECT id FROM ingredients WHERE name = 'Harina'),
    0.08,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'POS-PAS-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Harina')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'POS-PAS-001'),
    (SELECT id FROM ingredients WHERE name = 'Chocolate en polvo'),
    0.05,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'POS-PAS-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Chocolate en polvo')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'POS-PAS-001'),
    (SELECT id FROM ingredients WHERE name = 'Huevos'),
    2,
    'pieza'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'POS-PAS-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Huevos')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'POS-PAS-001'),
    (SELECT id FROM ingredients WHERE name = 'Mantequilla'),
    0.06,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'POS-PAS-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Mantequilla')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Helado
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'POS-HEL-002'),
    (SELECT id FROM ingredients WHERE name = 'Helado base'),
    0.15,
    'litro'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'POS-HEL-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Helado base')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Churros
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'POS-CHU-003'),
    (SELECT id FROM ingredients WHERE name = 'Harina'),
    0.1,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'POS-CHU-003')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Harina')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'POS-CHU-003'),
    (SELECT id FROM ingredients WHERE name = 'Azúcar'),
    0.05,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'POS-CHU-003')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Azúcar')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Ensalada César
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'ENS-CES-001'),
    (SELECT id FROM ingredients WHERE name = 'Lechuga'),
    0.15,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'ENS-CES-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Lechuga')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'ENS-CES-001'),
    (SELECT id FROM ingredients WHERE name = 'Aderezo césar'),
    0.05,
    'litro'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'ENS-CES-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Aderezo césar')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'ENS-CES-001'),
    (SELECT id FROM ingredients WHERE name = 'Queso mozzarella'),
    0.03,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'ENS-CES-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Queso mozzarella')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Ensalada Tropical
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'ENS-TRO-002'),
    (SELECT id FROM ingredients WHERE name = 'Frutas mixtas'),
    0.2,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'ENS-TRO-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Frutas mixtas')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Papas Fritas
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'SNA-PAP-001'),
    (SELECT id FROM ingredients WHERE name = 'Papas'),
    0.25,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'SNA-PAP-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Papas')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Nachos
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'SNA-NAC-002'),
    (SELECT id FROM ingredients WHERE name = 'Chips de maíz'),
    0.15,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'SNA-NAC-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Chips de maíz')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'SNA-NAC-002'),
    (SELECT id FROM ingredients WHERE name = 'Queso amarillo'),
    0.08,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'SNA-NAC-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Queso amarillo')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Jugo de Naranja
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'JUG-NAR-001'),
    (SELECT id FROM ingredients WHERE name = 'Naranjas'),
    0.3,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'JUG-NAR-001')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Naranjas')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- Batido de Fresa
INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'JUG-BAT-002'),
    (SELECT id FROM ingredients WHERE name = 'Fresas'),
    0.15,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'JUG-BAT-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Fresas')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'JUG-BAT-002'),
    (SELECT id FROM ingredients WHERE name = 'Leche'),
    0.2,
    'litro'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'JUG-BAT-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Leche')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

INSERT INTO recipes (product_id, ingredient_id, quantity, unit)
SELECT 
    (SELECT id FROM products WHERE sku = 'JUG-BAT-002'),
    (SELECT id FROM ingredients WHERE name = 'Azúcar'),
    0.02,
    'kg'
WHERE EXISTS (SELECT 1 FROM products WHERE sku = 'JUG-BAT-002')
  AND EXISTS (SELECT 1 FROM ingredients WHERE name = 'Azúcar')
ON CONFLICT (product_id, ingredient_id) DO NOTHING;

-- =====================================================
-- 5. CLIENTS (Customer Management & Loyalty)
-- =====================================================
INSERT INTO clients (name, phone, email, address, loyalty_points, total_purchases, is_active) VALUES
('Carlos López', '73456789', 'carlos.lopez@email.com', 'Av. Principal #123, La Paz', 240, 1250.50, true),
('Ana Martínez', '74567890', 'ana.martinez@email.com', 'Calle Comercio #456, La Paz', 180, 920.75, true),
('Pedro Sánchez', '75678901', 'pedro.sanchez@email.com', 'Zona Sur #789, La Paz', 95, 475.30, true),
('Lucía Fernández', '76789012', 'lucia.fernandez@email.com', NULL, 320, 1680.20, true),
('Roberto Díaz', '77890123', 'roberto.diaz@email.com', 'Av. 6 de Agosto #321, La Paz', 150, 780.90, true),
('Sofía Ramírez', '78901234', NULL, NULL, 60, 310.40, true),
('Miguel Torres', '79012345', 'miguel.torres@email.com', 'Calle Murillo #654, La Paz', 420, 2150.80, true),
('Carmen Ruiz', '70123457', 'carmen.ruiz@email.com', NULL, 210, 1080.60, true)
ON CONFLICT (phone) DO NOTHING;

-- =====================================================
-- 6. USER PROFILES (Additional Staff - Skip if exists)
-- =====================================================
INSERT INTO user_profiles (id, email, full_name, phone, pin_code, role, is_active)
SELECT gen_random_uuid(), 'gerente@cafepos.com', 'Gerente General', '72345679', '9012', 'manager', true
WHERE NOT EXISTS (SELECT 1 FROM user_profiles WHERE email = 'gerente@cafepos.com');

INSERT INTO user_profiles (id, email, full_name, phone, pin_code, role, is_active)
SELECT gen_random_uuid(), 'cocina@cafepos.com', 'Chef Principal', '73456780', '3456', 'kitchen', true
WHERE NOT EXISTS (SELECT 1 FROM user_profiles WHERE email = 'cocina@cafepos.com');

INSERT INTO user_profiles (id, email, full_name, phone, pin_code, role, is_active)
SELECT gen_random_uuid(), 'mesero@cafepos.com', 'Mesero Principal', '74567891', '7890', 'waiter', true
WHERE NOT EXISTS (SELECT 1 FROM user_profiles WHERE email = 'mesero@cafepos.com');

INSERT INTO user_profiles (id, email, full_name, phone, pin_code, role, is_active)
SELECT gen_random_uuid(), 'cajero2@cafepos.com', 'Cajero Auxiliar', '75678902', '2468', 'cashier', true
WHERE NOT EXISTS (SELECT 1 FROM user_profiles WHERE email = 'cajero2@cafepos.com');

-- =====================================================
-- 7. CASH SESSIONS (Register Operations)
-- =====================================================
-- Yesterday's closed session (Cashier) - Only if cajero@cafepos.com exists
INSERT INTO cash_sessions (user_id, opening_amount, opened_at, closed_at, closing_amount, total_cash, total_card, total_qr, total_sales, expected_amount, difference, is_active, notes)
SELECT 
    up.id,
    300,
    NOW() - INTERVAL '1 day' + INTERVAL '8 hours',
    NOW() - INTERVAL '1 day' + INTERVAL '20 hours',
    1850.50,
    980.50,
    620.00,
    250.00,
    1850.50,
    1850.50,
    0,
    false,
    'Turno matutino - Todo correcto'
FROM user_profiles up
WHERE up.email = 'cajero@cafepos.com'
  AND NOT EXISTS (
    SELECT 1 FROM cash_sessions cs 
    WHERE cs.opened_at::date = (CURRENT_DATE - INTERVAL '1 day')
      AND cs.user_id = up.id
  );

-- Yesterday's closed session (Admin) - Only if admin@cafepos.com exists
INSERT INTO cash_sessions (user_id, opening_amount, opened_at, closed_at, closing_amount, total_cash, total_card, total_qr, total_sales, expected_amount, difference, is_active, notes)
SELECT 
    up.id,
    250,
    NOW() - INTERVAL '1 day' + INTERVAL '14 hours',
    NOW() - INTERVAL '1 day' + INTERVAL '22 hours',
    1425.75,
    725.75,
    450.00,
    250.00,
    1425.75,
    1435.75,
    -10.00,
    false,
    'Turno vespertino - Diferencia menor'
FROM user_profiles up
WHERE up.email = 'admin@cafepos.com'
  AND NOT EXISTS (
    SELECT 1 FROM cash_sessions cs 
    WHERE cs.opened_at::date = (CURRENT_DATE - INTERVAL '1 day')
      AND cs.user_id = up.id
  );

-- =====================================================
-- 8. ORDERS & ORDER ITEMS (Sales System)
-- =====================================================
-- Order 1 - Delivered
WITH order_insert AS (
  INSERT INTO orders (order_number, user_id, client_id, cash_session_id, status, table_number, subtotal, tax, discount, total, created_at, completed_at, notes)
  SELECT 
      '20260112-0001',
      (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1),
      (SELECT id FROM clients WHERE phone = '73456789' LIMIT 1),
      (SELECT id FROM cash_sessions WHERE opened_at::date = (CURRENT_DATE - INTERVAL '1 day') 
       AND user_id = (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1) LIMIT 1),
      'delivered',
      'Mesa 5',
      125.00,
      16.25,
      0,
      141.25,
      NOW() - INTERVAL '1 day' + INTERVAL '10 hours',
      NOW() - INTERVAL '1 day' + INTERVAL '10 hours 25 minutes',
      NULL
  WHERE NOT EXISTS (SELECT 1 FROM orders WHERE order_number = '20260112-0001')
  RETURNING id
)
INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal, notes)
SELECT 
    (SELECT id FROM order_insert),
    p.id,
    p.name,
    CASE 
        WHEN p.sku = 'BEB-LAT-001' THEN 2
        WHEN p.sku = 'COM-SAN-001' THEN 2
        WHEN p.sku = 'POS-PAS-001' THEN 1
    END,
    p.price,
    CASE 
        WHEN p.sku = 'BEB-LAT-001' THEN p.price * 2
        WHEN p.sku = 'COM-SAN-001' THEN p.price * 2
        WHEN p.sku = 'POS-PAS-001' THEN p.price
    END,
    CASE WHEN p.sku = 'COM-SAN-001' THEN 'Sin cebolla' ELSE NULL END
FROM products p
WHERE p.sku IN ('BEB-LAT-001', 'COM-SAN-001', 'POS-PAS-001')
  AND EXISTS (SELECT 1 FROM order_insert);

-- Order 2 - Delivered
WITH order_insert AS (
  INSERT INTO orders (order_number, user_id, client_id, cash_session_id, status, table_number, subtotal, tax, discount, total, created_at, completed_at, notes)
  SELECT 
      '20260112-0002',
      (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1),
      (SELECT id FROM clients WHERE phone = '74567890' LIMIT 1),
      (SELECT id FROM cash_sessions WHERE opened_at::date = (CURRENT_DATE - INTERVAL '1 day') 
       AND user_id = (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1) LIMIT 1),
      'delivered',
      'Mesa 3',
      97.00,
      12.61,
      5.00,
      104.61,
      NOW() - INTERVAL '1 day' + INTERVAL '11 hours',
      NOW() - INTERVAL '1 day' + INTERVAL '11 hours 18 minutes',
      'Cliente frecuente'
  WHERE NOT EXISTS (SELECT 1 FROM orders WHERE order_number = '20260112-0002')
  RETURNING id
)
INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal, notes)
SELECT 
    (SELECT id FROM order_insert),
    p.id,
    p.name,
    CASE 
        WHEN p.sku = 'COM-PIZ-002' THEN 1
        WHEN p.sku = 'JUG-NAR-001' THEN 2
        WHEN p.sku = 'POS-HEL-002' THEN 1
    END,
    p.price,
    CASE 
        WHEN p.sku = 'COM-PIZ-002' THEN p.price
        WHEN p.sku = 'JUG-NAR-001' THEN p.price * 2
        WHEN p.sku = 'POS-HEL-002' THEN p.price
    END,
    CASE WHEN p.sku = 'POS-HEL-002' THEN 'Vainilla' ELSE NULL END
FROM products p
WHERE p.sku IN ('COM-PIZ-002', 'JUG-NAR-001', 'POS-HEL-002')
  AND EXISTS (SELECT 1 FROM order_insert);

-- Order 3 - Preparing (Kitchen Board) - Only if active session exists
WITH order_insert AS (
  INSERT INTO orders (order_number, user_id, client_id, cash_session_id, status, table_number, subtotal, tax, discount, total, created_at, notes)
  SELECT 
      '20260113-0002',
      (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1),
      (SELECT id FROM clients WHERE phone = '75678901' LIMIT 1),
      (SELECT id FROM cash_sessions WHERE is_active = true 
       AND user_id = (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1) LIMIT 1),
      'preparing',
      'Mesa 8',
      117.00,
      15.21,
      0,
      132.21,
      NOW() - INTERVAL '15 minutes',
      'Urgente'
  WHERE NOT EXISTS (SELECT 1 FROM orders WHERE order_number = '20260113-0002')
    AND EXISTS (SELECT 1 FROM cash_sessions WHERE is_active = true 
                AND user_id = (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1))
  RETURNING id
)
INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal, notes)
SELECT 
    (SELECT id FROM order_insert),
    p.id,
    p.name,
    CASE 
        WHEN p.sku = 'COM-TAC-003' THEN 2
        WHEN p.sku = 'SNA-NAC-002' THEN 1
        WHEN p.sku = 'JUG-BAT-002' THEN 1
    END,
    p.price,
    CASE 
        WHEN p.sku = 'COM-TAC-003' THEN p.price * 2
        WHEN p.sku = 'SNA-NAC-002' THEN p.price
        WHEN p.sku = 'JUG-BAT-002' THEN p.price
    END,
    CASE 
        WHEN p.sku = 'COM-TAC-003' THEN 'Bien cocidos'
        WHEN p.sku = 'JUG-BAT-002' THEN 'Extra cremoso'
        ELSE NULL 
    END
FROM products p
WHERE p.sku IN ('COM-TAC-003', 'SNA-NAC-002', 'JUG-BAT-002')
  AND EXISTS (SELECT 1 FROM order_insert);

-- Order 4 - Pending (Kitchen Board)
WITH order_insert AS (
  INSERT INTO orders (order_number, user_id, cash_session_id, status, table_number, subtotal, tax, discount, total, created_at, notes)
  SELECT 
      '20260113-0003',
      (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1),
      (SELECT id FROM cash_sessions WHERE is_active = true 
       AND user_id = (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1) LIMIT 1),
      'pending',
      'Mesa 2',
      90.00,
      11.70,
      0,
      101.70,
      NOW() - INTERVAL '5 minutes',
      NULL
  WHERE NOT EXISTS (SELECT 1 FROM orders WHERE order_number = '20260113-0003')
    AND EXISTS (SELECT 1 FROM cash_sessions WHERE is_active = true 
                AND user_id = (SELECT id FROM user_profiles WHERE email = 'cajero@cafepos.com' LIMIT 1))
  RETURNING id
)
INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal, notes)
SELECT 
    (SELECT id FROM order_insert),
    p.id,
    p.name,
    CASE 
        WHEN p.sku = 'ENS-CES-001' THEN 1
        WHEN p.sku = 'BEB-TEH-002' THEN 2
        WHEN p.sku = 'POS-CHU-003' THEN 2
    END,
    p.price,
    CASE 
        WHEN p.sku = 'ENS-CES-001' THEN p.price
        WHEN p.sku = 'BEB-TEH-002' THEN p.price * 2
        WHEN p.sku = 'POS-CHU-003' THEN p.price * 2
    END,
    CASE 
        WHEN p.sku = 'POS-CHU-003' THEN 'Con chocolate'
        ELSE NULL 
    END
FROM products p
WHERE p.sku IN ('ENS-CES-001', 'BEB-TEH-002', 'POS-CHU-003')
  AND EXISTS (SELECT 1 FROM order_insert);

-- =====================================================
-- 9. PAYMENTS (Transaction History)
-- =====================================================
-- Payment for Order 1
INSERT INTO payments (order_id, cash_session_id, amount, method, reference_number, notes)
SELECT 
    o.id,
    o.cash_session_id,
    o.total,
    'card',
    'CARD-20260112-001',
    'Visa terminación 4532'
FROM orders o
WHERE o.order_number = '20260112-0001'
  AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id = o.id);

-- Payment for Order 2
INSERT INTO payments (order_id, cash_session_id, amount, method, reference_number, notes)
SELECT 
    o.id,
    o.cash_session_id,
    o.total,
    'cash',
    NULL,
    'Pago en efectivo'
FROM orders o
WHERE o.order_number = '20260112-0002'
  AND NOT EXISTS (SELECT 1 FROM payments WHERE order_id = o.id);

-- =====================================================
-- 10. CASH TRANSACTIONS (Deposits/Withdrawals)
-- =====================================================
INSERT INTO cash_transactions (cash_session_id, user_id, type, amount, reason, notes)
SELECT 
    cs.id,
    up.id,
    'deposit',
    500.00,
    'Depósito adicional - Venta especial',
    'Evento corporativo'
FROM user_profiles up
CROSS JOIN cash_sessions cs
WHERE up.email = 'admin@cafepos.com'
  AND cs.opened_at::date = (CURRENT_DATE - INTERVAL '1 day')
  AND cs.user_id = up.id
  AND NOT EXISTS (
    SELECT 1 FROM cash_transactions ct
    WHERE ct.cash_session_id = cs.id 
      AND ct.type = 'deposit' 
      AND ct.amount = 500.00
  );

INSERT INTO cash_transactions (cash_session_id, user_id, type, amount, reason, notes)
SELECT 
    cs.id,
    up.id,
    'withdrawal',
    200.00,
    'Compra de insumos urgentes',
    'Pago a proveedor de emergencia'
FROM user_profiles up
CROSS JOIN cash_sessions cs
WHERE up.email = 'admin@cafepos.com'
  AND cs.opened_at::date = (CURRENT_DATE - INTERVAL '1 day')
  AND cs.user_id = up.id
  AND NOT EXISTS (
    SELECT 1 FROM cash_transactions ct
    WHERE ct.cash_session_id = cs.id 
      AND ct.type = 'withdrawal' 
      AND ct.amount = 200.00
  );

-- =====================================================
-- 11. INVENTORY MOVEMENTS (Stock Tracking)
-- =====================================================
-- Purchase movements (only if admin exists and ingredients exist)
INSERT INTO inventory_movements (ingredient_id, user_id, type, quantity, unit_cost, total_cost, reference_number, notes)
SELECT 
    i.id,
    (SELECT id FROM user_profiles WHERE email = 'admin@cafepos.com' LIMIT 1),
    'purchase',
    CASE 
        WHEN i.name = 'Café en grano' THEN 10
        WHEN i.name = 'Leche' THEN 50
        WHEN i.name = 'Harina' THEN 30
        WHEN i.name = 'Azúcar' THEN 25
        WHEN i.name = 'Pechuga de pollo' THEN 15
    END,
    i.unit_cost,
    CASE 
        WHEN i.name = 'Café en grano' THEN 450
        WHEN i.name = 'Leche' THEN 400
        WHEN i.name = 'Harina' THEN 540
        WHEN i.name = 'Azúcar' THEN 300
        WHEN i.name = 'Pechuga de pollo' THEN 1020
    END,
    CASE 
        WHEN i.name = 'Café en grano' THEN 'FAC-2026-001'
        WHEN i.name = 'Leche' THEN 'FAC-2026-002'
        WHEN i.name = 'Harina' THEN 'FAC-2026-003'
        WHEN i.name = 'Azúcar' THEN 'FAC-2026-004'
        WHEN i.name = 'Pechuga de pollo' THEN 'FAC-2026-005'
    END,
    CASE 
        WHEN i.name = 'Café en grano' THEN 'Compra mensual'
        WHEN i.name = 'Leche' THEN 'Abastecimiento semanal'
        WHEN i.name = 'Azúcar' THEN 'Reposición'
        WHEN i.name = 'Pechuga de pollo' THEN 'Pedido especial'
        ELSE NULL
    END
FROM ingredients i
WHERE i.name IN ('Café en grano', 'Leche', 'Harina', 'Azúcar', 'Pechuga de pollo')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@cafepos.com')
  AND NOT EXISTS (
    SELECT 1 FROM inventory_movements im
    WHERE im.ingredient_id = i.id 
      AND im.type = 'purchase'
      AND im.reference_number LIKE 'FAC-2026-%'
  );

-- Adjustment movements
INSERT INTO inventory_movements (ingredient_id, user_id, type, quantity, unit_cost, total_cost, notes)
SELECT 
    i.id,
    (SELECT id FROM user_profiles WHERE email = 'admin@cafepos.com' LIMIT 1),
    'adjustment',
    CASE 
        WHEN i.name = 'Chocolate en polvo' THEN -2
        WHEN i.name = 'Queso mozzarella' THEN 3
    END,
    i.unit_cost,
    CASE 
        WHEN i.name = 'Chocolate en polvo' THEN -190
        WHEN i.name = 'Queso mozzarella' THEN 255
    END,
    CASE 
        WHEN i.name = 'Chocolate en polvo' THEN 'Ajuste por inventario físico'
        WHEN i.name = 'Queso mozzarella' THEN 'Corrección de conteo'
    END
FROM ingredients i
WHERE i.name IN ('Chocolate en polvo', 'Queso mozzarella')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@cafepos.com')
  AND NOT EXISTS (
    SELECT 1 FROM inventory_movements im
    WHERE im.ingredient_id = i.id 
      AND im.type = 'adjustment'
  );

-- Waste movements (only if kitchen user exists)
INSERT INTO inventory_movements (ingredient_id, user_id, type, quantity, unit_cost, total_cost, notes)
SELECT 
    i.id,
    (SELECT id FROM user_profiles WHERE email = 'cocina@cafepos.com' LIMIT 1),
    'waste',
    CASE 
        WHEN i.name = 'Lechuga' THEN -1.5
        WHEN i.name = 'Tomate' THEN -2
    END,
    i.unit_cost,
    CASE 
        WHEN i.name = 'Lechuga' THEN -27
        WHEN i.name = 'Tomate' THEN -44
    END,
    CASE 
        WHEN i.name = 'Lechuga' THEN 'Producto en mal estado'
        WHEN i.name = 'Tomate' THEN 'Merma por maduración excesiva'
    END
FROM ingredients i
WHERE i.name IN ('Lechuga', 'Tomate')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'cocina@cafepos.com')
  AND NOT EXISTS (
    SELECT 1 FROM inventory_movements im
    WHERE im.ingredient_id = i.id 
      AND im.type = 'waste'
  );

-- =====================================================
-- DATA POPULATION COMPLETED
-- =====================================================
-- Summary:
-- ✅ 4 additional categories (with conflict handling)
-- ✅ 24 new ingredients with complete stock data (idempotent)
-- ✅ 14 new products with complete details (with conflict handling)
-- ✅ 35+ recipe relationships (fully idempotent with proper constraints)
-- ✅ 8 clients with loyalty data (with conflict handling)
-- ✅ 4 additional staff members (skip if exists)
-- ✅ 2 closed cash sessions (conditional inserts)
-- ✅ 4 orders (2 delivered, 1 preparing, 1 pending) - idempotent
-- ✅ 2 payments (idempotent)
-- ✅ 2 cash transactions (idempotent)
-- ✅ 9 inventory movements (idempotent)
-- 
-- All data respects foreign key constraints, handles duplicates gracefully,
-- and follows realistic POS business patterns for testing purposes.
-- Migration is now fully idempotent and can be run multiple times safely.
-- Fixed: All ingredients are created BEFORE being referenced in recipes.