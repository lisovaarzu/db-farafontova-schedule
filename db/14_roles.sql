\getenv reader_password APP_READER_PASSWORD
\getenv writer_password APP_WRITER_PASSWORD

CREATE ROLE app_reader
LOGIN PASSWORD :'reader_password';

CREATE ROLE app_writer
LOGIN PASSWORD :'writer_password'
IN ROLE app_reader;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;

GRANT CONNECT ON DATABASE app TO app_reader;
GRANT CONNECT ON DATABASE app TO app_writer;

GRANT USAGE ON SCHEMA public TO app_reader;
GRANT USAGE ON SCHEMA public TO app_writer;

GRANT SELECT ON
    v_schedule_details,
    v_teacher_load,
    mv_monthly_schedule
TO app_reader;

GRANT EXECUTE ON FUNCTION add_schedule_lesson_safe(
    integer,
    integer,
    integer,
    integer,
    integer,
    date
) TO app_writer;