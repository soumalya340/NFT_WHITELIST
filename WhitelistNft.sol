// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC4907.sol";

contract NFT is ERC721, Ownable ,IERC4907  {
    
    struct UserInfo 
    {
        address user;   // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    mapping (uint256  => UserInfo) internal _users;

    using Counters for Counters.Counter;
    uint256 constant maxSupply = 2000;


    string private revealURI;
    uint256 private totalSupply;
    string baseURI;
    uint private balance;

    bool private publicMintOpen = false;
    bool private allowListMintOpen = false;
    bool private pause = true;
    uint256 public publicprice;
    uint256 public allowListprice;
    uint256 private royaltypercentage = 5;
    mapping(address => bool) public allowList;

    bool public revealed = false;

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory BaseURI,
        uint256 _publicprice,
        uint256 _allowListprice
    ) ERC721("NFT", "NFT") {
        baseURI = BaseURI;
        publicprice = _publicprice;
        allowListprice = _allowListprice;
    }
    modifier whenNotpause() {
        require(pause == true, "The minting is stopped");
        _;
    }


    function setRoyalty(uint _royaltypercentage) public onlyOwner{
        royaltypercentage = _royaltypercentage;
    }


    function setRevealUri(string memory _uri) external onlyOwner{
        revealURI = _uri;
    }


    function reveal()  external onlyOwner {
        revealed = true;
    }

    //reveal the token URI by overriding the function 
    function tokenURI(uint256 tokenId) public view virtual override  returns (string memory) {
        require(tokenId <= totalSupply,"non existent toekn");
        if(revealed == true){
            return super.tokenURI(tokenId);
        }
        else{
            return revealURI;
        }

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


    /* RENTABLE */
    
    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires

    
    function setUser(uint256 tokenId, address user, uint64 expires) public override virtual{
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC4907: transfer caller is not owner nor approved");
        UserInfo storage info =  _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view override virtual returns(address){
        if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return  _users[tokenId].user;
        }
        else{
            return address(0);
        }
    }

    

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) public view override virtual returns(uint256){
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }

    //@notice If the owner wants to transfer the there should be zero users for that token
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        super._safeTransfer(from, to, tokenId, data);
        if (from != to && _users[tokenId].expires >= block.timestamp) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }


    // The following functions are overrides required by Solidity.

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function calculateRoyaltyFee(uint _publicprice , uint _royaltypercentage) internal pure returns (uint256) {
        return (_publicprice *  _royaltypercentage) / 100;
    }
}
