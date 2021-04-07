-- %1 Table name
-- %2 Geometry column
-- %3 Id column
-- ;;

CREATE VIRTUAL TABLE IF NOT EXISTS "rtree_%1_%2"
    USING rtree(id, minx, maxx, miny, maxy);;


CREATE TRIGGER "rtree_%1_%2_insert"
    AFTER INSERT ON "%1"
    WHEN (NEW.%2 NOT NULL AND NOT ST_IsEmpty(NEW.%2))
BEGIN
    INSERT OR REPLACE INTO "rtree_%1_%2" VALUES (
        NEW.%3,
        ST_MinX(NEW.%2), ST_MaxX(NEW.%2),
        ST_MinY(NEW.%2), ST_MaxY(NEW.%2)
    );
END;;

CREATE TRIGGER IF NOT EXISTS "rtree_%1_%2_update1"
    AFTER UPDATE OF %2 ON "%1"
    WHEN OLD.%3 = NEW.%3 AND (NEW.%2 NOT NULL AND NOT ST_IsEmpty(NEW.%2))
BEGIN
    INSERT OR REPLACE INTO "rtree_%1_%2" VALUES (
        NEW.%3,
        ST_MinX(NEW.%2), ST_MaxX(NEW.%2),
        ST_MinY(NEW.%2), ST_MaxY(NEW.%2)
    );
END;;

CREATE TRIGGER IF NOT EXISTS "rtree_%1_%2_update2"
    AFTER UPDATE OF %2 ON "%1"
    WHEN OLD.%3 = NEW.%3 AND (NEW.%2 IS NULL OR ST_IsEmpty(NEW.%2))
BEGIN
    DELETE FROM "rtree_%1_%2" WHERE id = OLD.%3;
END;;

CREATE TRIGGER IF NOT EXISTS "rtree_%1_%2_update3"
    AFTER UPDATE ON "%1"
    WHEN OLD.%3 != NEW.%3 AND (NEW.%2 NOT NULL AND NOT ST_IsEmpty(NEW.%2))
BEGIN
    DELETE FROM "rtree_%1_%2" WHERE id = OLD.%3;
    INSERT OR REPLACE INTO "rtree_%1_%2" VALUES (
        NEW.%3,
        ST_MinX(NEW.%2), ST_MaxX(NEW.%2),
        ST_MinY(NEW.%2), ST_MaxY(NEW.%2)
    );
END;;

CREATE TRIGGER IF NOT EXISTS "rtree_%1_%2_update4"
    AFTER UPDATE ON "%1"
    WHEN OLD.%3 != NEW.%3 AND (NEW.%2 IS NULL OR ST_IsEmpty(NEW.%2))
BEGIN
    DELETE FROM "rtree_%1_%2" WHERE id IN (OLD.%3, NEW.%3);
END;;

CREATE TRIGGER IF NOT EXISTS "rtree_%1_%2_delete"
    AFTER DELETE ON "%1"
    WHEN old.%2 NOT NULL
BEGIN
    DELETE FROM "rtree_%1_%2" WHERE id = OLD.%3;
END;;


--INSERT OR REPLACE INTO "rtree_%1_%2"
--  SELECT %3, ST_MinX(%2), ST_MaxX(%2), ST_MinY(%2), ST_MaxY(%2) FROM "%1";
