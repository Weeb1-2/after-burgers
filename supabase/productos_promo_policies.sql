-- OPCIONAL: si querés que las promos se guarden también en Supabase
-- (además del almacenamiento local de la app), ejecutá en SQL Editor:

CREATE POLICY "Insert productos"
ON public.productos FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "Update productos"
ON public.productos FOR UPDATE
TO anon, authenticated
USING (true);

CREATE POLICY "Delete productos"
ON public.productos FOR DELETE
TO anon, authenticated
USING (true);
