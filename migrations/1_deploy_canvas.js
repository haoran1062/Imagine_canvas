const Product = artifacts.require("Product");
const Canvas = artifacts.require("Canvas");

module.exports = function(deployer) {
  console.log("deploy canvas...");
  deployer.deploy(Canvas).then(function(){
    console.log("deploy product...");
    return deployer.deploy(Product, Canvas.address)
  });
};