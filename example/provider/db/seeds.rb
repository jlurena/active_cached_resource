person = Person.create!(
  first_name: "John",
  last_name: "Doe",
  age: 25
)

person.addresses.create!([
  { street: "123 Main St", city: "Springfield", state: "IL", zip: "62701" },
  { street: "456 Elm St", city: "Springfield", state: "IL", zip: "62702" }
])

person.create_company!(
  name: "Acme",
  street: "789 Maple St",
  city: "Springfield",
  state: "IL",
  zip: "62703"
)