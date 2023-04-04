library Voucher {

    struct NFTVoucher {
        address seller;
        address NFTAddress;
        uint256 tokenId;
        uint256 maxFractions;
        uint256 fractions;
        uint256 pricePerFraction;
        bool toMint;
        address royaltyKeeper;
        uint96 royaltyFees;
        string tokenURI;
        bytes signature;
    }

    struct offer {
        uint offerNumber;
        address offerer;
        uint tokenId;
        uint offeredPrice;
        address offeree;
        bytes signature;
    }

    
}