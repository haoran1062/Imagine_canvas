pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Canvas is ERC1155, Ownable {
    
    using Counters for Counters.Counter;
    // ProductInterface productContract;
    mapping(uint256=>address) public CanvasOwners;
    mapping(uint256=>uint256) public PixelSellPrice;
    mapping(address=>uint256) private OwnerAddressIdMap;
    address[] public lastModifiedAddress;
    address[] public OwnerAddress;
    uint256[] public OwnerPixels;
    uint256 public preSellId = 0;
    uint256[] private preSellPriceList = [1 * 10 ** 14, 1 * 10 ** 15, 1 * 10 ** 16, 2 * 10 ** 16, 4 * 10 ** 16, 8 * 10 ** 16];
    // uint256[] private preSellPriceList = [8 ether, 16 ether, 32 ether, 64 ether, 128 ether, 256 ether];
    uint256[] private preSellNumList = [0, 32, 64, 128, 256, 512, 1024];
    uint256 modifyId = 0;
    uint256[] private modifyPriceList = [1 * 10 ** 15, 1 * 10 ** 16, 2 * 10 ** 16, 4 * 10 ** 16];
    // uint256[] private modifyPriceList = [2 ether, 4 ether, 8 ether, 16 ether];
    uint256[] private modifyNumList = [0, 512, 1024, 2048];
    uint256 mintId = 0;
    uint256 lastMintModifiedId = 0;
    uint256 private maxMintNumber = 409600;
    bool private freeze = false;
    

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmRp3UQ6PwkaHg4UbkpnEZHybLKoNCRWx7u1nXGhenpii8/0000000000000000000000000000000000000000000000000000000000000000-metadata.json") {
        // productContract = ProductInterface(productAddress);
        _mint(msg.sender, 0, 32*32, "");
        OwnerAddress.push(msg.sender);
        OwnerPixels.push(1024);
        OwnerAddressIdMap[msg.sender] = 0;
        // for(uint256 i = 0; i < 32*32; i++){
        //     CanvasOwners[i] = msg.sender;   
        //     // PixelSellPrice[i] = 0;      
        // }
    }
    
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getEthBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserPixelsIDList(address userAddress) public view returns(uint256[] memory){
        require(balanceOf(userAddress, 0)>0);
        uint256 n = balanceOf(userAddress, 0);
        uint256[] memory userPixels = new uint256[](n);
        uint256 j = 0;
        for(uint256 i = 0; i < 32*32; i++){
            if(CanvasOwners[i] == userAddress){
                userPixels[j] = i;
                j++;
            }

        }
        return userPixels;
    }

    function getMintId() public view returns(uint256) {
        return mintId;
    }
    
    function userMintable(address userAddress) public view returns(bool) {
        if(userAddress == lastModifiedAddress[lastModifiedAddress.length-1] && lastMintModifiedId < modifyId && modifyId > 0 && mintId < maxMintNumber){
            return true;
        }
        return false;
    }

    function confirmMintModifiedId() public {
        require(userMintable(msg.sender));
        lastMintModifiedId = modifyId;
        mintId += 1;
    }

    function preMintProduct() public view returns(address[] memory, uint256[] memory){
        require(!freeze);
        
        require(userMintable(msg.sender));
        uint256 lastNum = lastModifiedAddress.length;
        require(msg.sender == lastModifiedAddress[lastNum-1]);
        uint256 n = OwnerAddress.length; 
        address[] memory to = new address[](n);
        uint256[] memory amounts = new uint256[](n);
        uint256 totalSupply = 0;
        
        for(uint256 i = 0; i < n; i++){
            address nowAddr = OwnerAddress[i];
            to[i] = nowAddr;
            // owner only have 16 in mint by pixel
            if(to[i] == owner() && OwnerPixels[i] > 16){
                amounts[i] = 16;
                totalSupply += 16;
                continue;
            }
            amounts[i] = OwnerPixels[i];
            totalSupply += amounts[i];
        }

        // reward to last 10 modified owners
        uint256 end = 0;
        if(lastNum >= 10){
            end = lastNum - 10;
        }
        uint256 j = 0;
        for(uint256 i = lastNum-1; i >= end; ){
            address nowAddr = lastModifiedAddress[i];
            uint256 giveNums = 0;
            if(j > 6){
                giveNums = 4;
            }
            else if(j >=2 && j <= 6){
                giveNums = 8;
            }
            else if(j == 1){
                giveNums = 16;
            }
            else if(j == 0){
                giveNums = 32;
            }
            for(uint256 k = 0; k < n; k++){
                if(to[k] == nowAddr){
                    amounts[k] += giveNums;
                    break;
                }
            }
            j++;
            totalSupply += giveNums;
            if(i > 0){
                i--;
            }
            else if(i == 0){
                break;
            }
        }
        

        // mintId += 1;
        // lastMintModifiedId = modifyId;

        // productContract.userMint(to, totalSupply, amounts, data);
        return (to, amounts);
    }

    function getPreSellCost(uint256[] memory amounts) public view returns(uint256){
        uint256 totalAmounts = 0;
        for(uint256 i = 0; i < amounts.length; i++){
            totalAmounts += amounts[i];
        }
        uint256 cost = 0;
        
        uint256 afterAmount = preSellId + totalAmounts;
        require(afterAmount >= preSellId);
        uint256 leftPoint = 0;
        uint256 rightPoint = 0;
        for(uint256 i = 0; i < preSellNumList.length-1; i++)
        {
            uint256 leftNum = preSellNumList[i];
            uint256 rightNum = preSellNumList[i+1];
            if(preSellId>=leftNum && preSellId < rightNum){
                leftPoint = i;
            }
            if(afterAmount>=leftNum && afterAmount <= rightNum)
            {
                rightPoint = i;
                break;
            }
        }
        uint256 nowId = preSellId;
        for(uint256 i = leftPoint; i <= rightPoint; i++)
        {
            cost += (preSellNumList[i+1] - nowId) * preSellPriceList[i];
            if(nowId + preSellNumList[i+1] - preSellNumList[i] <= afterAmount){
                nowId = preSellNumList[i+1];
            }
            else{
                cost -= (preSellNumList[i+1] - afterAmount) * preSellPriceList[i];
                break;
            }
        }
        return cost;
    }

    function preSellToUser(
        uint256[] memory ids, 
        uint256[] memory amounts, 
        uint256[] memory pixelIds, 
        bytes memory data) public payable{
        uint256 shouldCost = getPreSellCost(amounts);
        require(shouldCost == msg.value);
        address ownerAddress = owner();
        address userAddress = msg.sender;
        for(uint256 i = 0; i < pixelIds.length; i++){
            require(pixelIds[i] < 1024);
        }
        BatchTransferToUser(ownerAddress, userAddress, ids, amounts, pixelIds, data);

    }

    function userListPixelForSell(uint256[] memory pixelIdList, uint256[] memory sellPriceList) payable public {
        address ownerAddress = owner();
        require(pixelIdList.length == sellPriceList.length);
        if(!isApprovedForAll(msg.sender, ownerAddress)){
            setApprovalForAll(ownerAddress, true);
        }
            
        for(uint256 i = 0; i < pixelIdList.length; i++){
            require(CanvasOwners[pixelIdList[i]] == msg.sender);
            PixelSellPrice[pixelIdList[i]] = sellPriceList[i];
        }
        
    }

    function getPixelSellPrice(uint256 pixelId) public view returns(uint256){
        return PixelSellPrice[pixelId];
    }

    function contractURI() public view returns (string memory) {
        return uri(0);
    }

    function BatchTransferToUser(
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        uint256[] memory pixelIds, 
        bytes memory data)
         public{
        require(!freeze);
        if(OwnerAddressIdMap[to]==0){
            OwnerAddress.push(to);
            OwnerPixels.push(0);
            OwnerAddressIdMap[to] = OwnerAddress.length - 1;
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        for(uint i = 0; i < pixelIds.length; i++){
            CanvasOwners[pixelIds[i]] = to;
            preSellId += amounts[i];
            OwnerPixels[OwnerAddressIdMap[to]] += amounts[i];
            OwnerPixels[OwnerAddressIdMap[from]] -= amounts[i];
        }
    }

    function UserBuyPixel(uint256 pixelId) payable public{
        uint256 totalPrice = PixelSellPrice[pixelId];
        require(totalPrice > 0);
        require(totalPrice == msg.value);
        require(!freeze);
        
    }
    
    function sendPixelToBuyer(address buyer, uint256 pixelId, bytes memory data) payable public onlyOwner{
        address ownerAddress = owner();
        require(OwnerAddressIdMap[CanvasOwners[pixelId]] != 0 && OwnerPixels[OwnerAddressIdMap[CanvasOwners[pixelId]]] > 0);
        require(isApprovedForAll(CanvasOwners[pixelId], ownerAddress));
        safeTransferFrom(CanvasOwners[pixelId], ownerAddress, 0, 1, data);
        safeTransferFrom(ownerAddress, buyer, 0, 1, data);
        sendEthToSeller(CanvasOwners[pixelId], PixelSellPrice[pixelId]);
        // remove pixel from seller
        OwnerPixels[OwnerAddressIdMap[CanvasOwners[pixelId]]] -= 1;
        CanvasOwners[pixelId] = buyer;
        if(OwnerAddressIdMap[buyer] == 0){
            OwnerAddress.push(buyer);
            OwnerPixels.push(0);
            OwnerAddressIdMap[buyer] = OwnerAddress.length - 1;
        }
        // add pixel to buyer
        OwnerPixels[OwnerAddressIdMap[buyer]] += 1;
        
    }
    
    function sendEthToSeller(address receiveAddress, uint256 amounts) public payable onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        address payable receiver = payable(receiveAddress);
        require(getEthBalance() >= amounts);
        receiver.transfer(amounts);
        
    }
    

    function getPixelOwner(uint256 pixelId) public view returns(address){
        return CanvasOwners[pixelId];
    }

    function getModifyPirce() public view returns(uint256){
        uint256 nowPrice = modifyPriceList[modifyPriceList.length-1];
        for(uint256 i = 0; i < modifyPriceList.length-1; i++){
            if(modifyId >= modifyNumList[i] && modifyId < modifyNumList[i+1]){
               nowPrice = modifyPriceList[i];
               break;
            }
        }
        return nowPrice;
    }

    function modifyPixel(string memory URI) public payable {
        require(!freeze);
        uint256 nowPrice = modifyPriceList[modifyPriceList.length-1];
        for(uint256 i = 0; i < modifyPriceList.length-1; i++){
            if(modifyId >= modifyNumList[i] && modifyId < modifyNumList[i+1]){
               nowPrice = modifyPriceList[i];
               break;
            }
        }
        require(msg.value == nowPrice);
        _setURI(URI);
        
        lastModifiedAddress.push(msg.sender);
        
        
        modifyId += 1;
        
    }

    function updateURI(string memory URI)  public onlyOwner{
        require(!freeze);
        _setURI(URI);
    }

    function setMintMaxNumber(uint256 newNum) public onlyOwner{
        require(!freeze);
        maxMintNumber = newNum;
    }

    function setEmergencyMode(bool emergencyMode) public onlyOwner {
        freeze = emergencyMode;
    }

    // function() payable external {}

}