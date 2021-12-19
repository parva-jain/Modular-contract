// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibMeta {

    struct TokenMeta {
        uint256 saleId;
        address collectionAddress;
        uint256 tokenId;
        uint256 price;
        bool directSale;
        bool bidSale;
        bool status;
        address mintedBy;
        address currentOwner;
    }

    function transfer(TokenMeta memory token, address _to ) public pure{
        token.currentOwner = _to;
        token.status = false;
        token.directSale = false ;
        token.bidSale = false ;
    } 
}