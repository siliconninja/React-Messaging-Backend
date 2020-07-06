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