-- the assert function is for the unit tests
CREATE OR REPLACE FUNCTION assert(x numeric, y numeric) RETURNS void AS $$
BEGIN
    IF NOT (SELECT trunc(x, 2) = trunc(y, 2))
    THEN
        RAISE 'assert(%=%) failed (up to 2 decimal places, checked with trunc())!', x, y;
    END IF;
    RETURN;
END
$$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION assert(x text, y text) RETURNS void AS $$
BEGIN
    IF NOT (SELECT x = y)
    THEN
        RAISE 'assert(%=%) failed!', x, y;
    END IF;
    RETURN;
END
$$ LANGUAGE 'plpgsql' ;

