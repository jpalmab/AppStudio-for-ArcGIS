
CREATE TABLE IF NOT EXISTS Layers
(
    layerId integer PRIMARY KEY,
    info text
);

CREATE TABLE IF NOT EXISTS Features
(
    layerId integer,
    objectId integer,
    globalId text,
    creationDate date,
    creator text,
    editDate date,
    editor text,
    parentLayerid integer null,
    parentObjectId integer null,
    geometry blob,
    feature text,

    PRIMARY KEY(layerId, objectId),

    CONSTRAINT FK_Layer
        FOREIGN KEY (layerId)
        REFERENCES Layers(layerId)
        ON DELETE CASCADE,

    CONSTRAINT FK_ParentFeature
        FOREIGN KEY (parentLayerId, parentObjectId)
        REFERENCES Features(layerId, objectId)
        ON DELETE CASCADE
);

--CREATE TABLE IF NOT EXISTS Surveys
--(
--    layerId integer null,
--    objectId integer null,

--    created DATE,
--    updated DATE,
--    status INTEGER,
--    statusText TEXT,
--    data TEXT,
--    snippet TEXT,

--    PRIMARY KEY(layerId, objectId),

--    CONSTRAINT FK_Features
--        FOREIGN KEY (layerId, objectId)
--        REFERENCES Features(layerId, objectId)
--        ON DELETE CASCADE
--);

