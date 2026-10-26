CREATE TABLE teachers (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    email text NOT NULL UNIQUE
);

CREATE TABLE student_groups (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    course integer NOT NULL CHECK (course BETWEEN 1 AND 6)
);

CREATE TABLE rooms (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    building text NOT NULL,
    room_number text NOT NULL,
    capacity integer NOT NULL CHECK (capacity > 0),
    UNIQUE (building, room_number)
);

CREATE TABLE disciplines (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE
);

CREATE TABLE group_disciplines (
    group_id integer NOT NULL
        REFERENCES student_groups(id) ON DELETE CASCADE,
    discipline_id integer NOT NULL
        REFERENCES disciplines(id) ON DELETE CASCADE,

    PRIMARY KEY (group_id, discipline_id)
);

CREATE TABLE pair_slots (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pair_number integer NOT NULL UNIQUE
        CHECK (pair_number BETWEEN 1 AND 10),
    starts_at time NOT NULL,
    ends_at time NOT NULL,

    CHECK (ends_at > starts_at)
);

CREATE TABLE schedule_entries (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    group_id integer NOT NULL,
    discipline_id integer NOT NULL,

    teacher_id integer NOT NULL
        REFERENCES teachers(id) ON DELETE RESTRICT,

    room_id integer NOT NULL
        REFERENCES rooms(id) ON DELETE RESTRICT,

    pair_slot_id integer NOT NULL
        REFERENCES pair_slots(id) ON DELETE RESTRICT,

    lesson_date date NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),

    FOREIGN KEY (group_id, discipline_id)
        REFERENCES group_disciplines(group_id, discipline_id)
        ON DELETE RESTRICT,

    UNIQUE (lesson_date, pair_slot_id, room_id),
    UNIQUE (lesson_date, pair_slot_id, group_id)
);