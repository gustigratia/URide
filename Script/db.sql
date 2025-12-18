CREATE TYPE vehicletype_enum AS ENUM ('motor', 'mobil');
CREATE TYPE ordertype_enum AS ENUM ('onsite', 'pickup');
CREATE TYPE paymentmethod_enum AS ENUM ('cash', 'transfer');
CREATE TYPE orderstatus_enum AS ENUM ('pending', 'process', 'done', 'cancel');

CREATE TABLE public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone varchar,
  firstname varchar,
  lastname varchar,
  image text
);

CREATE TABLE public.workshops (
  id SERIAL PRIMARY KEY,
  bengkelname varchar,
  address varchar,
  description varchar,
  contact text,
  is_open boolean,
  latitude double precision,
  longitude double precision,
  rating numeric,
  image text,
  save boolean DEFAULT false,
  price bigint,
  userid uuid REFERENCES public.users(id),
  nomor_rekening bigint,
  bank varchar,
  open_time time,
  close_time time
);

CREATE TABLE public.service (
  id SERIAL PRIMARY KEY,
  workshop_id integer NOT NULL REFERENCES public.workshops(id) ON DELETE CASCADE,
  name varchar NOT NULL
);

CREATE TABLE public.vehicles (
  id SERIAL PRIMARY KEY,
  userid uuid REFERENCES public.users(id) ON DELETE CASCADE,
  vehicletype varchar,
  vehiclename vehicletype_enum,
  vehiclenumber varchar,
  kilometer integer,
  lastservicedate date,
  created_at timestamp DEFAULT CURRENT_TIMESTAMP,
  img text
);

CREATE TABLE public.orders (
  id SERIAL PRIMARY KEY,
  bengkelid integer REFERENCES public.workshops(id),
  userid uuid REFERENCES public.users(id),
  addressdetail varchar,
  vehicletype vehicletype_enum,
  ordertype ordertype_enum,
  orderdate date,
  price integer,
  rating integer,
  paymentmethod paymentmethod_enum,
  orderstatus orderstatus_enum,
  paymentstatus text DEFAULT 'pending',
  midtrans_order_id text
);


CREATE TABLE public.parking (
  id SERIAL PRIMARY KEY,
  userid uuid REFERENCES public.users(id) ON DELETE CASCADE,
  latitude double precision,
  longitude double precision,
  tanggal date,
  waktu time,
  status boolean DEFAULT false,
  nama_parkir text,
  alamat text
);

CREATE TABLE public.spbu (
  id SERIAL PRIMARY KEY,
  name varchar NOT NULL,
  rating double precision NOT NULL,
  has_toilet boolean NOT NULL,
  has_musholla boolean NOT NULL,
  image_url text NOT NULL,
  address text,
  open_time time,
  close_time time,
  latitude double precision,
  longitude double precision
);

