select name, firstname,id_user 
from utilisateur 
where id_user IN (
select distinct id_user 
from liste 
where list_name not like '%wish%' 
group by id_user 
having count(id_user) = (
select count(distinct list_type) 
from Liste));
