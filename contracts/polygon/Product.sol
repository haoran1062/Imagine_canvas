pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
// import "contracts/Canvas.sol";

interface CanvasInterface{
    function userMintable(address userAddress) external returns(bool);
}

contract Product is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    CanvasInterface canvasContract;

    constructor(address canvasAddress) ERC1155("https://gateway.pinata.cloud/ipfs/QmRp3UQ6PwkaHg4UbkpnEZHybLKoNCRWx7u1nXGhenpii8/0000000000000000000000000000000000000000000000000000000000000000-metadata.json") {
        _mint(msg.sender, _tokenIds.current(), 16, "");
        _tokenIds.increment();
        canvasContract = CanvasInterface(canvasAddress);
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getEthBalance() public view returns (uint) {
        return address(this).balance;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
       if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function BatchTransferToOwners(address from, address[] memory to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public{
        uint256[] memory tAmounts = new uint256[](1);
        uint256[] memory tIds = new uint256[](1);
        for(uint i = 0; i < to.length; i++){
            if(from != to[i]){
                tAmounts[0] = amounts[i];
                tIds[0] = ids[i];
                _safeBatchTransferFrom(from, to[i], tIds, tAmounts, data);
            }
        }
    }

    function updateURI(string memory URI)  public onlyOwner{
        _setURI(URI);
        
    }

    function sendEth(address receiveAddress, uint256 amounts) public payable onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        address payable receiver = payable(receiveAddress);
        require(getEthBalance() >= amounts);
        receiver.transfer(amounts);
        
    }

    function getMintPrice() view public returns(uint256){
        uint256 nowId = _tokenIds.current();
        uint256 price = 0;
        if(nowId < 16){
            price = 0;
        }
        else if(nowId >= 16 && nowId < 32){
            price = 4 * 10 ** 16;
        }
        else if(nowId >= 32 && nowId < 64){
            price = 8 * 10 ** 16;
        }
        else if(nowId >= 64 && nowId < 128){
            price = 16 * 10 ** 16;
        }
        else if(nowId >= 128 && nowId < 256){
            price = 32 * 10 ** 16;
        }
        else if(nowId >= 256){
            price = 64 * 10 ** 16;
        }

        return price;
    }

    function userMint(address[] memory to, uint256[] memory amounts, string memory URI, bytes memory data) payable public{
        require(canvasContract.userMintable(msg.sender), "minter should be the last modify canvas user!");
        uint256 mintPrice = getMintPrice();
        require(msg.value == mintPrice, "mint cost value not equal!");
        uint256 totalSupply = 0;
        for(uint256 i = 0; i < amounts.length; i++){
            totalSupply += amounts[i];
        }
        _mint(msg.sender, _tokenIds.current(), totalSupply, "");
        uint256[] memory ids = new uint256[](to.length);
        for(uint256 i = 0; i < to.length; i++){
            ids[i] = _tokenIds.current();
        }
        _tokenIds.increment();
        
        BatchTransferToOwners(msg.sender, to, ids, amounts, data);
        
        _setURI(URI);
        
        
        // require(_tokenIds.current() == 1, "tokenId != 1");
        
    }
}