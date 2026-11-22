require "rails_helper"

RSpec.describe User do
  describe "validations" do
    it "is valid with a name, unique email, and password" do
      user = build(:user)

      expect(user).to be_valid
    end

    it "requires a name" do
      user = build(:user, name: nil)

      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "requires an email" do
      user = build(:user, email: nil)

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a well-formed email" do
      user = build(:user, email: "not-an-email")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "requires a unique email, case-insensitively" do
      create(:user, email: "hr@acme.test")
      user = build(:user, email: "HR@acme.test")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "requires a password on create" do
      user = build(:user, password: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end

  describe "#authenticate" do
    it "returns the user when the password is correct" do
      user = create(:user, password: "correct-horse-battery-staple")

      expect(user.authenticate("correct-horse-battery-staple")).to eq(user)
    end

    it "returns false when the password is incorrect" do
      user = create(:user, password: "correct-horse-battery-staple")

      expect(user.authenticate("wrong-password")).to be(false)
    end
  end

  describe "email normalization" do
    it "downcases and strips the email before saving" do
      user = create(:user, email: "  HR@ACME.test  ")

      expect(user.email).to eq("hr@acme.test")
    end
  end
end
