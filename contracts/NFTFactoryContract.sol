// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTStorage.sol";
import "./Libraries/LibMeta.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./TokenERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTFactoryContract is
    NFTV1Storage,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    address contractAddress = address(this);

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ERC721Upgradeable.__ERC721_init("NFTFactoryContract", "NFTMRKT");
    }

    event TokenMetaReturn(LibMeta.TokenMeta data, uint256 id);
    event BatchMint(uint256 _totalNft, string msg);

    modifier onlyOwnerOfToken(uint256 _tokenID) {
        require(msg.sender == ownerOf(_tokenID));
        _;
    }

    modifier onlyOwnerOfCollectionToken(address _collectionAddress, uint256 _tokenId) {
        require(msg.sender == TokenERC721(_collectionAddress).ownerOf(_tokenId));
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, tokenId);
        LibMeta.transfer(_tokenMeta[tokenId], to);        
    }

// Change in BuyNFT LibMeta Function

    function BuyNFT(uint256 _tokenId) public payable nonReentrant {
        LibMeta.TokenMeta memory meta = _tokenMeta[_tokenId];
        require(msg.sender != address(0) && msg.sender != meta.currentOwner);
        require(meta.bidSale == false);
        require(msg.value >= meta.price, "Price >= nft price");

        payable(meta.currentOwner).transfer(msg.value);
        _transfer(meta.currentOwner, payable(msg.sender), _tokenId);
        LibMeta.transfer(_tokenMeta[_tokenId],msg.sender);
    }

    function SellNFT(uint256 _tokenId, uint256 _price)
        public
        onlyOwnerOfToken(_tokenId)
    {   
        require(_price > 0);
        _tokenMeta[_tokenId].bidSale = false;
        _tokenMeta[_tokenId].directSale = true;
        _tokenMeta[_tokenId].price = _price;
    }

    function sellNFT(address _contractAddress, uint256 _tokenId, uint256 _price) 
    public 
    onlyOwnerOfCollectionToken(_contractAddress, _tokenId)
    {
        _tokenIdTracker.increment();

        string memory tokenUri = TokenERC721(_contractAddress).tokenURI(_tokenId);

        LibMeta.TokenMeta memory meta = LibMeta.TokenMeta(
            _contractAddress,
            _tokenId,
            _price,
            "",
            tokenUri,
            true,
            false,
            false,
            collectionToOwner[_contractAddress],
            _msgSender(),
            _msgSender(),
            0
        );

         _tokenMeta[_tokenIdTracker.current()] = meta;

        emit TokenMetaReturn(meta, _tokenIdTracker.current());

    }

    function mintNFT(
        string memory _tokenURI,
        string memory _name
    ) public returns (uint256) {

        _tokenIdTracker.increment();

        _mint(msg.sender, _tokenIdTracker.current());

        LibMeta.TokenMeta memory meta = LibMeta.TokenMeta(
            contractAddress,
            _tokenIdTracker.current(),
            0,
            _name,
            _tokenURI,
            false,
            false,
            false,
            _msgSender(),
            _msgSender(),
            _msgSender(),
            0
        );
        _tokenMeta[_tokenIdTracker.current()] = meta;

        emit TokenMetaReturn(meta, _tokenIdTracker.current());

        return _tokenIdTracker.current();
    }

    function batchMint(uint _totalNFT, string[] memory _name, string[] memory _tokenURI) external nonReentrant returns (bool) {
        require(_totalNFT <= 15, "15 or less allowed");
        require(_name.length == _tokenURI.length, "Total Uri and TotalNft does not match");

         for(uint i = 0; i< _totalNFT; i++) {
            mintNFT(_tokenURI[i], _name[i]);
        }
        emit BatchMint(_totalNFT, "Batch mint success");
        return true;
    }
}
