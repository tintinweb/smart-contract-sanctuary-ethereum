// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct AstroChartArgs {
    uint16[] datetimeOfBirth;
    int16[] cityOfBirth;
    bool exists;
    uint32 generation;
    uint32 alreadyBredCount;
}

library AstroChartLib {

    // the limit for initial mint
    uint private constant INITIAL_MINT_LIMIT = 366;
    uint256 private constant SALES_START_PRICE = 0.5 ether;
    uint256 private constant priceDropDuration = 600; // 10 mins
    uint256 private constant priceDropAmount = 0.025 ether;
    uint256 private constant priceDropFloor = 0.2 ether;

    struct LibStorage {
        // already minted for initial minting
        uint256 initalMintCount;
        uint256 salesStartTime;
        // initial deposit
        uint256 initialDeposit;
        // initial mint's conflict detector
        mapping (bytes32 => bool) initialMintDate2Exists;
        // record tokenId to origin data
        mapping (uint256 => AstroChartArgs) tokenIdToAstroData;
        // record owner to pending withdraws
        mapping (address => uint) pendingWithdraws;
        // record tokenId to breed next generation's price
        mapping (uint256 => uint256) tokenIdToBreedPrice;
        
        uint256 nextTokenId;
        // charge the oracle gas fee for oracle operator to submit transaction
        uint256 oracleGasFee;
    }

    // return a struct storage pointer for accessing the state variables
    function libStorage() internal pure returns (LibStorage storage ds) {
        bytes32 position = keccak256("AstroChartLib.storage");
        assembly { ds.slot := position }
    }

    function _initNextTokenId() public {
        libStorage().nextTokenId = 1;
    }

    /**
    * @dev calculates the next token ID based on totalSupply
    * @return uint256 for the next token ID
    */
    function _nextTokenId() private returns (uint256) {
        uint256 res = libStorage().nextTokenId;
        libStorage().nextTokenId += 1;
        return res;
    }

    function setOracleGasFee(uint256 _fee) public {
        libStorage().oracleGasFee = _fee;
    }

    /**
    set the initial mint price, only can be done by owner
     */
    function setStartSalesTime(uint256 _salesStartTime) public {
        libStorage().salesStartTime = _salesStartTime;
    }

    function initialDeposit() public view returns (uint256){
        return libStorage().initialDeposit;
    }

    function initialMintCount() public view returns ( uint256 ) {
        return libStorage().initalMintCount;
    }

    function initialMintDry(uint16[] calldata datetimeOfBirth, int16[] calldata cityOfBirth) public returns ( uint256 tokenId ){
        //checks
        require(libStorage().initalMintCount < INITIAL_MINT_LIMIT, "IMLA");

        require(msg.value >= getPrice() + libStorage().oracleGasFee, "IMSPWI+O");

        require(libStorage().salesStartTime > 0, "SSTSLTZ");

        require(libStorage().initialMintDate2Exists[dateToBytes32(datetimeOfBirth)] == false, "IMDAE");
        
        _checkForDateAndCity(datetimeOfBirth, cityOfBirth);
        
        //effects
        AstroChartArgs memory args = AstroChartArgs({datetimeOfBirth: datetimeOfBirth, cityOfBirth: cityOfBirth, exists: true, generation: 0, alreadyBredCount: 0});

        tokenId = _nextTokenId();
        libStorage().tokenIdToAstroData[tokenId] = args;
        libStorage().initalMintCount ++;
        libStorage().initialDeposit += msg.value;
        libStorage().initialMintDate2Exists[dateToBytes32(datetimeOfBirth)] = true;
    }

    function dateToBytes32(uint16[] calldata datetimeOfBirth) private pure returns ( bytes32 ) {
        uint16 year = datetimeOfBirth[0]; uint16 month = datetimeOfBirth[1]; uint16 day = datetimeOfBirth[2];
        bytes memory encoded = abi.encodePacked(year, month, day);
        return bytesToBytes32(encoded);
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32 out) {
        for (uint8 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
    }

    function getPrice() public view returns (uint256) {
        if (libStorage().salesStartTime == 0) {
            return 0;
        }

        // Public sales
        uint256 dropCount = (block.timestamp - libStorage().salesStartTime) / priceDropDuration;
            // It takes 12 dropCount to reach at 0.2 floor price in Dutch Auction
        return
        dropCount < 12
            ? SALES_START_PRICE - dropCount * priceDropAmount
            : priceDropFloor;
    }

    /**
    require datetimeOfBirth.length == 6, or else throw "datetime not valid" as "DTNV"
    require year >= 0 && year < 3000, or else throw "year not valid" as "YNV";
    require month >= 0 && month <= 12, or else throw "month not valid" as "MONV";
    require day >= 0 && day <= 31, or else throw "day not valid" as "DNV"
    require hour >= 0 && hour <= 24, or else throw  "hour not valid" as "HNV"
    require minute >= 0 && minute <= 60, or else throw "minute not valid" as "MINV"
    require second >= 0 && second <= 60, or else throw "second not valid" as "SNV"
    require cityOfBirth.length == 3, or else throw "city not valid" as "CNV
     */
    function _checkForDateAndCity(uint16[] calldata datetimeOfBirth, int16[] calldata cityOfBirth) private pure {
        require(datetimeOfBirth.length == 6, "DTNV");
        uint16 year = datetimeOfBirth[0]; uint16 month = datetimeOfBirth[1]; uint16 day = datetimeOfBirth[2]; 
        uint16 hour = datetimeOfBirth[3]; uint16 minute = datetimeOfBirth[4]; uint16 second = datetimeOfBirth[5];
        require(year >= 0 && year < 3000, "YNV");
        require(month >= 0 && month <= 12, "MONV");
        require(day >= 0 && day <= 31, "DNV");
        require(hour >= 0 && hour <= 24, "HNV");
        require(minute >= 0 && minute <= 60, "MNV");
        require(second >= 0 && second <= 60, "SNV");

        require(cityOfBirth.length == 3, "CNV");
    }

    function setBreedPrice(uint256 tokenId, uint256 breedPrice) public {
        //effects
        libStorage().tokenIdToBreedPrice[tokenId] = breedPrice;
    }

    function withdrawBreedFee() public {
        //checks
        require(libStorage().pendingWithdraws[msg.sender] > 0, "PWMLTZ");

        //effects
        libStorage().pendingWithdraws[msg.sender] = 0;

        //interactions
        payable(msg.sender).transfer(libStorage().pendingWithdraws[msg.sender]);
    }

    function breedFromDry(uint256 fromTokenId, uint16[] calldata datetimeOfBirth, int16[] calldata cityOfBirth, address ownerOfFromToken) public returns (uint256 bredTokenId){
        //checks
        uint256 breedPrice = libStorage().tokenIdToBreedPrice[fromTokenId];
        require(msg.value >= breedPrice + libStorage().oracleGasFee, "LTBP+O");
        _checkForDateAndCity(datetimeOfBirth, cityOfBirth);
        AstroChartArgs storage astroDataOfParentToken = libStorage().tokenIdToAstroData[fromTokenId];
        require(datetimeOfBirth[1] == astroDataOfParentToken.datetimeOfBirth[1], "MNE");
        require(datetimeOfBirth[2] == astroDataOfParentToken.datetimeOfBirth[2], "DNE");
        require(astroDataOfParentToken.alreadyBredCount < breedingLimitationOf(astroDataOfParentToken.generation), "BGBL");

        //effects
        AstroChartArgs memory args = AstroChartArgs({
            datetimeOfBirth: datetimeOfBirth, cityOfBirth: cityOfBirth, 
            exists: true, generation: astroDataOfParentToken.generation + 1, alreadyBredCount: 0
        });

        //set bredToken to astro data
        bredTokenId = _nextTokenId();
        libStorage().tokenIdToAstroData[bredTokenId] = args;

        //update pending withdraw of from token's owner
        libStorage().pendingWithdraws[ownerOfFromToken] = breedPrice;

        //add oracleGadFee to initialDeposit
        libStorage().initialDeposit += msg.value - breedPrice;
        // update alreadyBredCount of fromToken
        astroDataOfParentToken.alreadyBredCount += 1;
    }

    function breedingLimitationOf(uint32 generation) public pure returns (uint32 res) {
        uint32 revisedGen = generation > 10 ? 0 : 10 - generation;
        res = uint32(1) << revisedGen;
    }

    function getAstroArgsOf(uint256 tokenId) external view returns (AstroChartArgs memory) {
        return libStorage().tokenIdToAstroData[tokenId];
    }

    function getPendingWithdraw() public view returns( uint256 ){
        return libStorage().pendingWithdraws[msg.sender];
    }

    
}