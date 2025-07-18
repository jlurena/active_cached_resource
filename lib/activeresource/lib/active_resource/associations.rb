# frozen_string_literal: true

require "pry-byebug" # IGNORE: This line is for debugging purposes and should be removed in production code.
module ActiveResource::Associations
  module Builder
    autoload :Association, "activeresource/lib/active_resource/associations/builder/association"
    autoload :HasMany,     "activeresource/lib/active_resource/associations/builder/has_many"
    autoload :HasOne,      "activeresource/lib/active_resource/associations/builder/has_one"
    autoload :BelongsTo,   "activeresource/lib/active_resource/associations/builder/belongs_to"
  end



  # Specifies a one-to-many association.
  #
  # === Options
  # [:class_name]
  #   Specify the class name of the association. This class name would
  #   be used for resolving the association class.
  #
  # ==== Example for [:class_name] - option
  # GET /posts/123.json delivers following response body:
  #   {
  #     title: "ActiveResource now has associations",
  #     body: "Lorem Ipsum"
  #     comments: [
  #       {
  #         content: "..."
  #       },
  #       {
  #         content: "..."
  #       }
  #     ]
  #   }
  # ====
  #
  # <tt>has_many :comments, :class_name => 'myblog/comment'</tt>
  # Would resolve those comments into the <tt>Myblog::Comment</tt> class.
  #
  # If the response body does not contain an attribute matching the association name
  # a request sent to the index action under the current resource.
  # For the example above, if the comments are not present the requested path would be:
  # GET /posts/123/comments.xml
  def has_many(name, options = {})
    Builder::HasMany.build(self, name, options)
  end

  # Specifies a one-to-one association.
  #
  # === Options
  # [:class_name]
  #   Specify the class name of the association. This class name would
  #   be used for resolving the association class.
  #
  # ==== Example for [:class_name] - option
  # GET /posts/1.json delivers following response body:
  #   {
  #     title: "ActiveResource now has associations",
  #     body: "Lorem Ipsum",
  #     author: {
  #       name: "Gabby Blogger",
  #     }
  #   }
  # ====
  #
  # <tt>has_one :author, :class_name => 'myblog/author'</tt>
  # Would resolve this author into the <tt>Myblog::Author</tt> class.
  #
  # If the response body does not contain an attribute matching the association name
  # a request is sent to a singleton path under the current resource.
  # For example, if a Product class <tt>has_one :inventory</tt> calling <tt>Product#inventory</tt>
  # will generate a request on /products/:product_id/inventory.json.
  #
  def has_one(name, options = {})
    Builder::HasOne.build(self, name, options)
  end

  # Specifies a one-to-one association with another class. This class should only be used
  # if this class contains the foreign key.
  #
  # Methods will be added for retrieval and query for a single associated object, for which
  # this object holds an id:
  #
  # [association(force_reload = false)]
  #   Returns the associated object. +nil+ is returned if the foreign key is +nil+.
  #   Throws a ActiveResource::ResourceNotFound exception if the foreign key is not +nil+
  #   and the resource is not found.
  #
  # (+association+ is replaced with the symbol passed as the first argument, so
  # <tt>belongs_to :post</tt> would add among others <tt>post.nil?</tt>.
  #
  # === Example
  #
  # A Comment class declares <tt>belongs_to :post</tt>, which will add:
  # * <tt>Comment#post</tt> (similar to <tt>Post.find(post_id)</tt>)
  # The declaration can also include an options hash to specialize the behavior of the association.
  #
  # === Options
  # [:class_name]
  #   Specify the class name for the association. Use it only if that name can't be inferred from association name.
  #   So <tt>belongs_to :post</tt> will by default be linked to the Post class, but if the real class name is Article,
  #   you'll have to specify it with this option.
  # [:foreign_key]
  #   Specify the foreign key used for the association. By default this is guessed to be the name
  #   of the association with an "_id" suffix. So a class that defines a <tt>belongs_to :post</tt>
  #   association will use "post_id" as the default <tt>:foreign_key</tt>. Similarly,
  #   <tt>belongs_to :article, :class_name => "Post"</tt> will use a foreign key
  #   of "article_id".
  #
  # Option examples:
  # <tt>belongs_to :customer, :class_name => 'User'</tt>
  # Creates a belongs_to association called customer which is represented through the <tt>User</tt> class.
  #
  # <tt>belongs_to :customer, :foreign_key => 'user_id'</tt>
  # Creates a belongs_to association called customer which would be resolved by the foreign_key <tt>user_id</tt> instead of <tt>customer_id</tt>
  #
  def belongs_to(name, options = {})
    Builder::BelongsTo.build(self, name, options)
  end

  # Defines the belongs_to association finder method
  def defines_belongs_to_finder_method(reflection)
    method_name = reflection.name
    ivar_name = :"@#{method_name}"

    if method_defined?(method_name)
      instance_variable_set(ivar_name, nil)
      remove_method(method_name)
    end

    define_method(method_name) do
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      elsif attributes.include?(method_name)
        attributes[method_name]
      elsif association_id = send(reflection.foreign_key)
        instance_variable_set(ivar_name, reflection.klass.find(association_id))
      end
    end
  end

  def defines_has_many_finder_method(reflection)
    method_name = reflection.name
    ivar_name = :"@#{method_name}"

    define_method(method_name) do
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      elsif attributes.include?(method_name)
        attributes[method_name]
      elsif !new_record?
        # Association would be set on custom primary key if explicitly defined, otherwise use convention _id
        assoc_key = self.class.custom_primary_key || "#{self.class.element_name}_id"
        instance_variable_set(ivar_name, reflection.klass.find(:all, params: { assoc_key => self.id }))
      else
        instance_variable_set(ivar_name, reflection.klass.none)
      end
    end
  end

  # Defines the has_one association
  def defines_has_one_finder_method(reflection)
    method_name = reflection.name
    ivar_name = :"@#{method_name}"

    define_method(method_name) do
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      elsif attributes.include?(method_name)
        attributes[method_name]
      elsif reflection.klass.respond_to?(:singleton_name)
        instance_variable_set(ivar_name, reflection.klass.find(params: { "#{self.class.element_name}_id": self.id }))
      else
        instance_variable_set(ivar_name, reflection.klass.find(:one, from: "/#{self.class.collection_name}/#{self.id}/#{method_name}#{self.class.format_extension}"))
      end
    end
  end
end
