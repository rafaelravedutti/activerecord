# -*- coding: utf-8 -*-
# Cria uma nova base de dados a cada vez. 
# Para criar o bd execute "ruby criaSchema.rb".

require 'rubygems'
require 'active_record'

# As duas linhas abaixo indicam o SGBD a ser usado (sqlite3) e o nome
# do arquivo que contém o banco de dados (Aulas.sqlite3)
ActiveRecord::Base.establish_connection :adapter => "sqlite3",
                                        :database => "Aulas.sqlite3" 
                    
# As linhas abaixo criam a tabela "pessoas" dentro do banco
# "Aulas.sqlite3", indicando os atributos e os seus tipos. No caso,
# todos são "string", mas tem várias outras oportunidades.
ActiveRecord::Base.connection.create_table :pessoas do |t|  
  t.string   :last_name 
  t.string   :first_name 
  t.string   :address 
  t.string   :city 
end

# Sugestão de bibliografia:
# http://www.amazon.com/Pro-Active-Record-Databases-Experts/dp/1590598474

=begin
----->>>> 
----- Dica de como implementar relações:
1x1 (Pessoa Profissão)
1xn (Pessoa Sapatos)
nxn (Pessoa Casa)
----->>>> 


ActiveRecord::Base.connection.create_table :profissaos do |t|  
  t.integer :pessoa_id
  ... demais atributos ... 
end

ActiveRecord::Base.connection.create_table :sapatos do |t|  
  t.integer :pessoa_id  
  ... demais atributos ... 
end

ActiveRecord::Base.connection.create_table :casas do |t|  
  ... demais atributos ... 
end

ActiveRecord::Base.connection.create_table :pessoas do |t|  
  t.integer :profissao_id
  ... demais atributos ... 
end

ActiveRecord::Base.connection.create_table :casas_pessoas do |t|  
  t.integer :pessoa_id
  t.integer :casa_id
  ... demais atributos ... 
end

=end
