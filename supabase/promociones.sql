-- OPCIONAL: la app ya guarda promos en `productos` (categoria = promo)
-- sin necesidad de esta tabla. Ejecutá esto solo si querés tabla dedicada.
CREATE TABLE IF NOT EXISTS public.promociones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'otro',
  etiqueta TEXT DEFAULT '',
  activa BOOLEAN NOT NULL DEFAULT true,
  fecha_inicio TIMESTAMPTZ NOT NULL,
  fecha_fin TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.promociones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura pública promociones"
ON public.promociones FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Admin insert promociones"
ON public.promociones FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "Admin update promociones"
ON public.promociones FOR UPDATE
TO anon, authenticated
USING (true);

CREATE POLICY "Admin delete promociones"
ON public.promociones FOR DELETE
TO anon, authenticated
USING (true);
