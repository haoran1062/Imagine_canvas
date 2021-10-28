const Canvas = artifacts.require("Canvas");
const Product = artifacts.require("Product");

contract("Canvas", accounts => {
  it("account[1] buy 1 pixel from contract", async () => {

    const instance = await Canvas.deployed();
    var balance0 = await instance.balanceOf("0xb91fba80a1514907ec390e32d9cb6c86b2fa1109", 0);
    var balance1 = await instance.balanceOf("0xeb2af4882fc71c625f3ded4c5e0eba30dce0642b", 0);
    console.log("owner have " + balance0 + " pixel");
    console.log("account[1] have " + balance1 + " pixel");
    var cost = await instance.getPreSellCost([2]);
    console.log("should pay " + cost + " wei.");

    await instance.preSellToUser([0, 0], [1, 1], [2, 3], "0xeb2af4882fc71c625f3ded4c5e0eba30dce0642b", {from: accounts[1], value: cost});
    balance0 = await instance.balanceOf("0xb91fba80a1514907ec390e32d9cb6c86b2fa1109", 0);
    balance1 = await instance.balanceOf("0xeb2af4882fc71c625f3ded4c5e0eba30dce0642b", 0);
    console.log("after pre-sell owner have " + balance0 + " pixel");
    console.log("after pre-sell account[1] have " + balance1 + " pixel");
  });

  it("account[1] sell 1 pixel & account[2] buy that pixel", async () => {

    const instance = await Canvas.deployed();
    var address0 = "0xb91FBa80a1514907ec390E32D9cb6c86b2fa1109";
    var address1 = "0xeb2af4882fc71c625f3ded4c5e0eba30dce0642b";
    var address2 = "0x26755d5c9f1f8a7004784673f8c57a5c33d1ab60";
    var balance0 = await instance.balanceOf(address1, 0);
    var balance1 = await instance.balanceOf(address2, 0);
    console.log("account[1] have " + balance0 + " pixel");
    console.log("account[2] have " + balance1 + " pixel");

    await instance.userListPixelForSell([2], [10**10], {from: accounts[1]});
    var cost = await instance.getPixelSellPrice(2);
    console.log("should pay " + cost + " wei.");

    await instance.UserBuyPixel(2, {from: accounts[2], value: cost});
    await instance.sendPixelToBuyer(address2, 2, address0, {from: accounts[0]});

    balance0 = await instance.balanceOf(address1, 0);
    balance1 = await instance.balanceOf(address2, 0);
    console.log("after sell account[1] have " + balance0 + " pixel");
    console.log("after sell account[2] have " + balance1 + " pixel");
  });

  it("account[2] modify pixel 2, account[1] modify pixel 3", async () => {

    const instance = await Canvas.deployed();
    var cost = await instance.getModifyPirce();
    console.log("modify pixel should cost " + cost + " wei.");

    await instance.modifyPixel("https://gateway.pinata.cloud/ipfs/QmcDSjndkaiqxBnsDwzd6eVnXFttxduAApFhWJh48KRUWm/{id}-metadata.json", {from: accounts[1], value: cost});
    console.log("modify pixel success!");

    var cost = await instance.getModifyPirce();
    console.log("modify pixel should cost " + cost + " wei.");

    await instance.modifyPixel("https://gateway.pinata.cloud/ipfs/QmcDSjndkaiqxBnsDwzd6eVnXFttxduAApFhWJh48KRUWm/{id}-metadata.json", {from: accounts[2], value: cost});
    console.log("modify pixel success!");

  });

  it("mint product", async () => {

    const instance = await Canvas.deployed();
    const product_instance = await Product.deployed();
    var address2 = "0x26755d5c9f1f8a7004784673f8c57a5c33d1ab60";
    var to = null;
    var amount = null;
    var can_mint = await instance.userMintable(address2);
    console.log(can_mint);
    var result = await instance.preMintProduct({from: accounts[2]});
    console.log("return: ");
    console.log(result);
    to = result['0'];
    amount = result['1'];
    console.log(to);
    console.log(amount);
    var cost = await product_instance.getMintPrice();
    console.log("mint product should cost " + cost + " wei.");
    var uri = "https://gateway.pinata.cloud/ipfs/QmcDSjndkaiqxBnsDwzd6eVnXFttxduAApFhWJh48KRUWm/{id}-metadata.json";
    var data = "0xeb2af4882fc71c625f3ded4c5e0eba30dce0642b";
    
    await product_instance.userMint(to, amount, uri, data, {from: accounts[2], value: cost});
    await instance.confirmMintModifiedId({from: accounts[2]});
    
  });


  
});
