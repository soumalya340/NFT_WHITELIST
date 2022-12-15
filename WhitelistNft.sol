// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Web3Builders is ERC721, Ownable {
    using Counters for Counters.Counter;
    uint256 constant maxSupply = 2000;

    uint256 private totalSupply;
    string baseURI;
    uint private balance;

    bool private publicMintOpen = false;
    bool private allowListMintOpen = false;
    bool private pause = true;
    uint256 public publicprice;
    uint256 public allowListprice;
    uint256 private royaltyfee = 5;
    mapping(address => bool) public allowList;

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory BaseURI,
        uint256 _publicprice,
        uint256 _allowListprice
    ) ERC721("Web3Builders", "WEB3") {
        baseURI = BaseURI;
        publicprice = _publicprice;
        allowListprice = _allowListprice;
    }

    modifier whenNotpause() {
        require(pause == true, "The minting is stopped");
        _;
    }

    function Pause(bool _pause) external onlyOwner {
        pause = _pause;
    }

    function setPrice(
        uint256 _publicprice,
        uint256 _allowlistprice
    ) external onlyOwner {
        publicprice = _publicprice;
        allowListprice = _allowlistprice;
    }

    // Modify the mint windows0
    function editMintWindows(
        bool _publicMintOpen,
        bool _allowListMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    // require only the allowList people to mint
    // Add publicMint and allowListMintOpen Variables
    function allowListMint() public payable whenNotpause {
        require(allowListMintOpen, "Allowlist Mint Closed");
        require(allowList[msg.sender], "You are not on the allow list");
        require(msg.value == allowListprice, "Not Enough Funds");
        require(totalSupply <= (maxSupply * 30) / 100, "Supply is exceeded");
        internalMint();
    }

    // Add Payment
    // Add limiting of supply
    function publicMint() public payable whenNotpause {
        require(publicMintOpen, "Public Mint Closed");
        require(!allowListMintOpen, "Still the minting can't be started");
        require(msg.value == publicprice, "Not Enough Funds");
        internalMint();
    }

    function internalMint() internal {
        require(totalSupply < maxSupply, "We Sold Out!");
        uint256 tokenId = _tokenIdCounter.current();
        totalSupply = tokenId;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function withdraw(address _addr) external onlyOwner whenNotpause {
        // get the balance of the contract
        uint256 balalnce = address(this).balance;
        payable(_addr).transfer(balalnce);
    }

    // Populate the Allow List
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }

    // set the royalty for the creator
    function TransferNFT(address to, uint256 tokenId) public payable {
        uint _royalty = (publicprice * royaltyfee) / 100;
        require(msg.value == _royalty, "Not enough money to transfer");
        _safeTransfer(msg.sender, to, tokenId, "");
        payable(address(this)).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getRoyaltyFee() external view returns (uint256) {
        return (publicprice * royaltyfee) / 100;
    }
}
