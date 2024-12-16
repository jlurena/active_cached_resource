# typed: strong

class Customer
  class Friend
    class Brother
      class Child; end
    end
  end
end

class Person
  class Books
    class UnnamedResource; end
  end

  class Address; end
  class Street
    class State
      class NotableRiver; end
    end
  end
end

# Defining specific instances based on the structure
class Luis < Customer; end

class JK < Customer::Friend; end

class Mateo < Customer::Friend::Brother; end
class Felipe < Customer::Friend::Brother; end

class Edith < Customer::Friend::Brother::Child; end
class Martha < Customer::Friend::Brother::Child; end

class Bryan < Customer::Friend::Brother::Child; end
class Luke < Customer::Friend::Brother::Child; end

class Eduardo < Customer::Friend; end

class Sebas < Customer::Friend::Brother; end
class Elsa < Customer::Friend::Brother; end
class Milena < Customer::Friend::Brother; end

class Andres < Customer::Friend::Brother::Child; end
class Jorge < Customer::Friend::Brother::Child; end
class Natacha < Customer::Friend::Brother::Child; end
