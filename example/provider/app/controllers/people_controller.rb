class PeopleController < ApplicationController
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  http_basic_authenticate_with name: "admin", password: "secret"

  # Index expects a response with a 200 status code
  # @see https://github.com/rails/activeresource#find
  def index
    persons = Person.includes(:addresses, :company)
    render json: persons.as_json(include: {addresses: {}, company: {}})
  end

  # Show expects a single JSON object with a 200 status code
  # If the record is not found, expects a 404 status code
  # @see https://github.com/rails/activeresource#find
  def show
    person = Person.includes(:addresses, :company).find_by(id: params[:id])
    if person
      render json: person.as_json(include: {addresses: {}, company: {}})
    else
      head :not_found
    end
  end

  # Create expects an empty response with 201 status and a Location header
  # @see https://github.com/rails/activeresource#update
  def create
    person = Person.new(person_params)
    if person.save
      head :created, location: person_url(person)
    else
      render json: person.errors, status: :unprocessable_entity
    end
  end

  # Update expects an empty response with a 204 status code
  # @see https://github.com/rails/activeresource#update
  def update
    person = Person.find_by(id: params[:id])
    if person&.update(person_params)
      head :no_content
    else
      render json: person&.errors || {error: "Person not found"}, status: :unprocessable_entity
    end
  end

  # Destroy expects an empty response with a 200 status code
  # @see https://github.com/rails/activeresource#delete
  def destroy
    person = Person.find_by(id: params[:id])
    if person&.destroy
      head :ok
    else
      render json: person&.errors || {error: "Person not found"}, status: :unprocessable_entity
    end
  end

  private

  # Strong parameters for Person
  def person_params
    params.require(:person).permit(
      :first_name, :last_name, :age,
      addresses_attributes: [:id, :street, :city, :state, :zip, :_destroy],
      company_attributes: [:id, :name, :street, :city, :state, :zip, :_destroy]
    )
  end
end
