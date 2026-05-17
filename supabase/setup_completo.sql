-- AFTER BURGERS — Setup completo (ejecutar una vez en Supabase → SQL Editor)
-- Crea tabla promociones, políticas RLS y habilita escritura segura en productos

-- ========== PRODUCTOS ==========
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura pública productos" ON public.productos;
DROP POLICY IF EXISTS "Insert productos" ON public.productos;
DROP POLICY IF EXISTS "Update productos" ON public.productos;
DROP POLICY IF EXISTS "Delete productos" ON public.productos;

CREATE POLICY "Lectura pública productos"
ON public.productos FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Insert productos"
ON public.productos FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Update productos"
ON public.productos FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Delete productos"
ON public.productos FOR DELETE TO anon, authenticated USING (true);

-- ========== PROMOCIONES (tabla dedicada) ==========
CREATE TABLE IF NOT EXISTS public.promociones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'otro',
  etiqueta TEXT DEFAULT '',
  activa BOOLEAN NOT NULL DEFAULT true,
  fecha_inicio TIMESTAMPTZ NOT NULL,
  fecha_fin TIMESTAMPTZ NOT NULL,
  producto_objetivo TEXT,
  descuento_porcentaje INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.promociones
  ADD COLUMN IF NOT EXISTS producto_objetivo TEXT,
  ADD COLUMN IF NOT EXISTS descuento_porcentaje INT NOT NULL DEFAULT 0;

ALTER TABLE public.promociones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura pública promociones" ON public.promociones;
DROP POLICY IF EXISTS "Insert promociones" ON public.promociones;
DROP POLICY IF EXISTS "Update promociones" ON public.promociones;
DROP POLICY IF EXISTS "Delete promociones" ON public.promociones;

CREATE POLICY "Lectura pública promociones"
ON public.promociones FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Insert promociones"
ON public.promociones FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Update promociones"
ON public.promociones FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Delete promociones"
ON public.promociones FOR DELETE TO anon, authenticated USING (true);
