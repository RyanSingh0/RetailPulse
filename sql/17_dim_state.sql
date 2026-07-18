-- =====================================================================
-- 17_dim_state.sql  ·  RetailPulse
-- State lookup with full name, region and lat/long centroid.
-- ---------------------------------------------------------------------
-- Why: Power BI maps mis-geocode bare Brazilian 2-letter codes (PA -> USA
-- Pennsylvania, MT -> Montana, AL -> Alabama, etc.). Feeding the map
-- LAT/LONG instead removes all ambiguity. Centroids are the average of
-- the Olist geolocation points per state.
-- Use: import this table, relate dim_state[state] -> dim_customer[state]
-- (1:many), then build the map with Latitude/Longitude + Total Revenue.
-- =====================================================================

DROP TABLE IF EXISTS mart.dim_state;

CREATE TABLE mart.dim_state (
    state       TEXT PRIMARY KEY,
    state_name  TEXT,
    region      TEXT,
    latitude    NUMERIC,
    longitude   NUMERIC
);

INSERT INTO mart.dim_state (state, state_name, region, latitude, longitude) VALUES
 ('AC','Acre',                'North',       -9.7026, -68.4519),
 ('AL','Alagoas',             'Northeast',   -9.6128, -36.0629),
 ('AM','Amazonas',            'North',       -3.3493, -60.5374),
 ('AP','Amapa',                'North',        0.0860, -51.2343),
 ('BA','Bahia',               'Northeast',  -13.0531, -39.5629),
 ('CE','Ceara',                'Northeast',   -4.3632, -39.0041),
 ('DF','Distrito Federal',    'Center-West',-15.8109, -47.9696),
 ('ES','Espirito Santo',      'Southeast',  -20.1106, -40.4961),
 ('GO','Goias',                'Center-West',-16.5776, -49.3342),
 ('MA','Maranhao',            'Northeast',   -3.7990, -44.8186),
 ('MG','Minas Gerais',        'Southeast',  -19.8654, -44.4208),
 ('MS','Mato Grosso do Sul',  'Center-West',-20.7650, -54.5321),
 ('MT','Mato Grosso',         'Center-West',-14.1609, -55.7128),
 ('PA','Para',                 'North',       -2.6597, -49.5130),
 ('PB','Paraiba',             'Northeast',   -7.0971, -35.8266),
 ('PE','Pernambuco',          'Northeast',   -8.1791, -35.7589),
 ('PI','Piaui',                'Northeast',   -5.7550, -42.5095),
 ('PR','Parana',              'South',      -24.7970, -50.8818),
 ('RJ','Rio de Janeiro',      'Southeast',  -22.7455, -43.1568),
 ('RN','Rio Grande do Norte', 'Northeast',   -5.8567, -35.9901),
 ('RO','Rondonia',            'North',      -10.3413, -62.7206),
 ('RR','Roraima',             'North',        2.7171, -60.6729),
 ('RS','Rio Grande do Sul',   'South',      -29.6796, -52.0349),
 ('SC','Santa Catarina',      'South',      -27.2225, -49.6179),
 ('SE','Sergipe',             'Northeast',  -10.8662, -37.1812),
 ('SP','Sao Paulo',           'Southeast',  -23.1554, -47.0842),
 ('TO','Tocantins',           'North',       -9.5037, -48.3487);

SELECT COUNT(*) AS states FROM mart.dim_state;   -- expect 27
