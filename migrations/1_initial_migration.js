const privateSale = artifacts.require("PrivateSale");

module.exports = function (deployer) {
    deployer.deploy(privateSale, 
      1000000000000, "0x5747a7f258Bd38908A551CE6d76b8C2A428D7586", "0x22C6d5281296e52A77d1F88D85136A003148145a", 1738302422, "0xfeEd3CdC8a0F4b24B430bd635774f5a31D1CB8A1");
  };