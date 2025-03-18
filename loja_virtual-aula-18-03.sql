create table clientes(
	id int auto_increment primary key,
    nome varchar(100) not null,
    email varchar(100) unique not null,
    telefone varchar(15),
    endereco text,
    criado_em timestamp default current_timestamp
);

create table produtos(
	id int auto_increment primary key,
    nome varchar(100) not null,
    descricao text,
    preco decimal(10,2) not null,
    estoque int default 0,
    criado_em timestamp default current_timestamp
);

create table pedidos(
	id int auto_increment primary key,
    cliente_id int not null,
    data_pedido timestamp default current_timestamp,
    status enum('pendente', 'enviado', 'concluido', 'cancelado') default 'pendente',
    total decimal(10,2) default 0,
    foreign key (cliente_id) references clientes(id)
);

create table itens_pedidos(
	id int auto_increment primary key,
    pedido_id int not null,
    produto_id int not null,
    quantidade int not null,
    preco_unitario decimal(10,2) not null,
    subtotal decimal(10,2) generated always as (quantidade * preco_unitario) stored,
    foreign key (pedido_id) references pedidos(id),
    foreign key (produto_id) references produtos(id)
);

create table pagamentos(
	id int auto_increment primary key,
	pedido_id int not null,
    data_pagamento timestamp default current_timestamp,
    valor decimal(10,2) not null,
    metodo enum('cartao', 'boleto', 'pix', 'dinheiro'),
    status enum('aprovado', 'pendente', 'recusado') default 'pendente',
    foreign key (pedido_id) references pedidos(id)
);

insert into clientes (nome, email, telefone, endereco)
values 
('joao silva', 'joao@email.com', '(11) 98765-4321', 'rua a, 123, sao paulo'),
('maria oliveira', 'maria@email.com', '(21) 91234-5678', 'av b, 456, rio de janeiro');

insert into produtos (nome, descricao, preco, estoque)
values
('notebook', 'notebook com 16gb ram e 512gb ssd', 4500.00, 10),
('mouse', 'mouse sem fio com alta precisao', 150.00, 50),
('cadeira gamer', 'cadeira ergonomica e confortavel', 1200.00, 5);

insert into pedidos (cliente_id, total)
values
(1,0),
(2,0);

insert into itens_pedidos (pedido_id, produto_id, quantidade, preco_unitario)
values
(1, 1, 1, 4500.00),
(1, 2, 2, 150.00),
(2, 3, 1, 1200.00);

update pedidos
set total = (
	select sum(subtotal)
    from itens_pedidos
    where pedido_id = pedidos.id
)
where id in (1, 2);

select p.id as pedido, c.nome as cliente, p.data_pedido, p.total, p.status
from pedidos p
inner join clientes c on p.cliente_id = c.id;

select c.nome as cliente, p.id as pedido, p.total
from clientes c
left join pedidos p on c.id = p.cliente_id;

select id, pedido_id, valor,
	case
		when status = 'aprovado' then 'pagamento aprovado'
        when status = 'pendente' then 'aguardando pagamento'
        else 'pagamento recusado'
	end as status_pagamento
from pagamentos;

select prod.nome as produto, sum(ip.quantidade) as total_vendido, sum(ip.subtotal) as total_arrecadado
from itens_pedidos ip
inner join produtos prod on ip.produto_id = prod.id
group by prod.nome;

select nome from clientes
union all
select nome from produtos;

#exercicios

# 1.
select c.nome as cliente, count(p.id) as n_total, sum(p.total)
from clientes c
inner join pedidos p on p.cliente_id = p.id
group by c.id;

# 2.
select c.nome as cliente, count(p.id) as n_total, sum(p.total)
from clientes c
inner join pedidos p on p.cliente_id = p.id
where p.cliente_id <> 0 
group by c.id;

# 3.
	select c.nome as cliente, count(p.id) as n_total, sum(p.total) as 'valor_total',
	case
		when sum(p.total) < 1000.00 then 'baixo gasto'
        when sum(p.total) between 1000.00 and 5000.00 then 'gasto moderado'
        else 'alto gasto'
	end as status_pagamento
from pagamentos;

# 4.
select c.nome as cliente, count(p.id) as n_total, sum(p.total)
from clientes c
inner join pedidos p on p.cliente_id = p.id
group by c.id
order by p.total desc;

# 5.
select c.nome as cliente, count(p.id) as n_total, sum(p.total), p.data_pedido
from clientes c
inner join pedidos p on p.cliente_id = p.id
group by c.id
order by p.data_pedido desc;

insert into pagamentos (pedido_id, data_pagamento, valor, metodo, status)
values
(1, '2025-03-01 10:00:00', 4500.00, 'Cartão', 'Pendente'),
(2, '2025-03-01 15:30:00', 2500.00, 'Pix', 'Aprovado');

create view resumo_vendas as
select
	c.nome as nome_cliente,
    p.id as id_pedido,
    p.data_pedido as data_pedido,
    p.total as total_pedido,
    p.status as status_pedido,
    pag.status as status_pagamento,
    pag.metodo as metodo_pagamento
from
	pedidos p
inner join 
	clientes c on p.cliente_id = c.id
inner join 
	pagamentos as pag on p.id = pag.pedido_id;
    

select nome_cliente
from resumo_vendas
where status_pagamento = 'pendente';

select id_pedido
from resumo_vendas
where status_pagamento = 'aprovado';

create view trinta as
select
	c.nome as nome_cliente,
    p.id as id_pedido,
    p.data_pedido as data_pedido,
    p.total as total_pedido,
    p.status as status_pedido,
    pag.status as status_pagamento,
    pag.metodo as metodo_pagamento
from
	pedidos p
inner join 
	clientes c on p.cliente_id = c.id
inner join 
	pagamentos as pag on p.id = pag.pedido_id
where
	data_pedido >= date_sub(curdate(), interval 30 day);
    
select *
from trinta;

with resumo_clientes as (
select
	c.nome as nome_cliente,
    count(p.id) as total_pedidos,
    sum(p.total) as soma_valores
from
	clientes as c
inner join
	pedidos p on c.id - p.cliente_id
group by
	c.id, c.nome
)
select
	nome_cliente,
    total_pedidos,
    soma_valores,
    case
		when soma_valores < 1000 then 'gasto baixo'
        when soma_valores between 1000 and 5000 then 'gasto medio'
        else 'gasto alto'
        end as classificacao
from
	resumo_clientes
order by soma_valores desc;

alter view resumo_produtos as
select 
	p.nome as nome_produto,
    count(i.quantidade) as quantidade_vendas,
    sum(i.subtotal) as receita
from
	produtos p
inner join 
	itens_pedidos i on p.id = i.produto_id
group by p.nome;

select * from resumo_produtos;



##produtos_vendidos
create or replace view produtos_vendidos as 
select 
	p.id as id_produto,
	p.nome as nome_produto,
	count(i.quantidade) as quantidade_vendas
from 
	produtos p
inner join 
	itens_pedidos i on p.id = i.produto_id
group by p.id, p.nome;

select * from produtos_vendidos;
    
##clientes_vendas
create or replace view clientes_vendas as 
select
	c.id,
	c.nome as nome_cliente,
    count(p.id) as vendas_realizadas
from
	clientes c
inner join
	pedidos p on c.id = p.cliente_id
group by c.id, c.nome;
    
select * from clientes_vendas;


##receita_total
create or replace view receita_total as
select
	sum(p.total) as total_vendido
from 
	pedidos p;

select * from receita_total;

select 
	cv.nome_cliente,
    cv.vendas_realizadas,
    pv.nome_produto as produto_mais_comprado,
    rt.total_vendido as receia_loja,
    case
		when cv.vendas_realizadas < 1000 then 'baixo custo'
        when cv.vendas_realizadas between 1000 and 5000 then 'gasto medio'
        else 'alto gasto'
		end as classificacao_cliente
	from
		clientes_vendas cv
	left join
		produtos_vendidos pv on cv.id = pv.id_produto
	cross join
		receita_total rt
	order by cv.vendas_realizadas desc;
			
            
	







    
    
    
    
			









