-- Objetivo: Revisar si los codigos categoricos (VendorID, RatecodeID, payment_type) respetan el diccionario de datos de la TLC (3.6).
-- Fuente: read_parquet('/workspace/data/raw/*/*/*.parquet').
-- Nota: diccionario TLC: RatecodeID 1-6 y 99 (desconocido); payment_type 0-6; VendorID 1, 2, 6, 7.
SELECT 'VendorID' AS columna, coalesce(VendorID::VARCHAR, '(nulo)') AS codigo, split_part(filename, '/', 5) AS taxi_type, count(*) AS registros
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true) GROUP BY ALL
UNION ALL
SELECT 'RatecodeID', coalesce(RatecodeID::VARCHAR, '(nulo)'), split_part(filename, '/', 5), count(*)
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true) GROUP BY ALL
UNION ALL
SELECT 'payment_type', coalesce(payment_type::VARCHAR, '(nulo)'), split_part(filename, '/', 5), count(*)
FROM read_parquet('/workspace/data/raw/*/*/*.parquet', union_by_name = true, filename = true) GROUP BY ALL
ORDER BY columna, taxi_type, registros DESC;
