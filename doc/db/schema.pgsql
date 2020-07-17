CREATE DATABASE messagesdb WITH ENCODING 'UTF8' LC_COLLATE='English_United States' LC_CTYPE='English_United States';
\c messagesdb

-- messages table
CREATE TABLE public.messages
(
    id serial NOT NULL,
    email character varying(50)[] NOT NULL,
    message character varying(500)[] NOT NULL,
    PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE public.messages
    OWNER to postgres;

-- create users

CREATE ROLE messagesdb_user WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	CONNECTION LIMIT -1
	PASSWORD 'messagesdb_user'; -- yes, this plaintext password is there. this won't ever be done in production.

-- If using the PGAdmin4 GUI, run these in Tools > Query Tool (or similar) to grant permissions on the messages table.
-- You can also right click on a table and use the Table permissions wizard and copy whatever's under the "SQL" tab.
GRANT CONNECT ON DATABASE messagesdb TO messagesdb_user;

GRANT INSERT, SELECT, DELETE ON TABLE public.messages TO messagesdb_user;
-- need this sequence thing for graphql as well
-- https://stackoverflow.com/a/9325195
GRANT USAGE, SELECT ON SEQUENCE messages_id_seq TO messagesdb_user;

# ================= EXAMPLE QUERIES FOR SUBSCRIPTIONS ======================
# example test DB queries (to practice triggering subscriptions)
select pg_notify(
  'postgraphile:onNewMessage',
  '{}'
);

# gets useful information as well as know that we got a new message
select pg_notify(
  'postgraphile:onNewMessage',
  json_build_object(
    '__node__', json_build_array(
      'messages', -- IMPORTANT: this is not always exactly the table name; base64
              -- decode an existing nodeId to see what it should be.
      6      -- The primary key (for multiple keys, list them all).
    )
  )::text
);

# ===================== TRIGGERS 'n FUNCTIONS ==================================
-- FUNCTION: public.on_message_added()
CREATE FUNCTION public.on_message_added()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
AS $BODY$
BEGIN
	  PERFORM pg_notify( -- because SELECT will give us annoying errors like Query has no destination for result data after trigger (thanks for the hint, Postgres console! HINT: look in the postgres console (e.g. in a Query Editor with PGAdmin4)
                         -- for hints, and graphql won't output them (just the error msg) by default. thanks /s)
	  'postgraphile:onNewMessage',
	  json_build_object(
		'__node__', json_build_array(
		  'messages', -- IMPORTANT: this is not always exactly the table name; base64
				  -- decode an existing nodeId to see what it should be.
		  NEW.id      -- The primary key (for multiple keys, list them all).
		)
	  )::text
	);
    RETURN NEW; -- apparently we have to return something...
END;
$BODY$;

ALTER FUNCTION public.on_message_added()
    OWNER TO postgres;

CREATE TRIGGER on_message_added
AFTER INSERT
ON messages
FOR EACH ROW
EXECUTE PROCEDURE on_message_added();