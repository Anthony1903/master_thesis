# encoding: utf-8

require 'rubygems'
require 'rgl/dot'
require "rgl/adjacency"

class Graph

	def initialize(name, vertices, edges)
		@name = name
		@vertices = vertices
		@edges = edges
		$graph_path = "app/assets/images/graphs/"
		Dir.mkdir($graph_path) unless File.directory?($graph_path) 
	end

=begin
	
	Crée un fichier ".png" représentant une structure d'arbre en fonction des 
	paramètres recu par le constructeur. 
		- name : nom du fichier
		- verticies : ensemble ne noms de noeuds
		- edges : ensemble de liens entre noeuds (pairs de noms de noeuds)

=end
	def save()

		dg = RGL::DirectedAdjacencyGraph[]

		@vertices.each do |v|
			dg.add_vertex(v)
		end

		@edges.each do |e|
			dg.add_edge(e[0],e[1])
		end 

		dg.write_to_graphic_file(fmt='png', dotfile="#{$graph_path}#{@name}")

	end

	# Génère un fichier png en utilisant un objet Graph. Déduit les paramètres vertices, 
	# edge et name depuis l'arbre de racine root passé en argument.
	def self.gen_graph(root)
		vertices = []
		edges = []
		vertices << root.data
		gen_graph_aux(vertices, edges, root)
		g = Graph.new("import_graph", vertices, edges)
		g.save()
	end

private

	# Complète les listes vertices et edges, depuis les enfants du noeud node, récursivement.
	def self.gen_graph_aux(vertices, edges, node)
		node.children.each do |c|
			vertices << c.data
			edges << [node.data, c.data]
			self.gen_graph_aux(vertices, edges, c)
		end
	end

end
 