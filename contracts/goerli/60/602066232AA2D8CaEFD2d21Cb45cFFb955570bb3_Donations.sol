/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// File: contracts/vinfts/donations.sol


pragma solidity ^0.8.17;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        return a / b;
    }
}

contract Donations {
    using SafeMath for uint;
    address public admin;
    address public VITreasury;
    uint256 public VIRoyalty;
    uint256 public minEthDonation = 0.001 ether;

    purchaseData[] allPurchases;
    rePurchaseData[] allRePurchases;

    mapping(address => purchaseData[]) userPurchases;
    mapping(address => rePurchaseData[]) userRePurchases;

    struct purchaseData {
        uint timestamp;
        address buyer;
        address beneficiary;
        uint donation;
    }

    struct rePurchaseData {
        uint timestamp;
        address buyer;
        address beneficiary;
        uint donation;
        address artist;
        uint artist_spercentage;
    }

    constructor(address _treasury) {
        admin = msg.sender;
        VITreasury = _treasury;
        VIRoyalty = 2;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "VINFTS: NOT AUTHORIZED");
        _;
    }

    // GETTER FUNCTIONS
    function getUserPurchases(address _doner) public view returns(purchaseData[] memory){
        return userPurchases[_doner];
    }

    function getUserRePurchases(address _doner) public view returns(rePurchaseData[] memory){
        return userRePurchases[_doner];
    }

    function getAllPurchases() public view returns(purchaseData[] memory) {
        return allPurchases;
    }

    function getAllRePurchases() public view returns(rePurchaseData[] memory){
        return allRePurchases;
    }


    // SETTER FUNCTIONS
    // function to change VINFTS treasury wallet;
    function changeTreasury(address _treasury) onlyOwner public {
        VITreasury = _treasury;
    }

    // function to change royalty sent to VITreasuty wallet;
    function changeRoyalty(uint _royalty) onlyOwner public {
        // if you want 2% percent, you should set "_royalty" to be 2;
        VIRoyalty = _royalty;
    }

    function purchaseToken(address _beneficiary) public payable {
        uint _toBeneficiary = msg.value.mul(100-VIRoyalty).div(100); // calculate amount will be sent to beneficiary;
        uint _transferCost = tx.gasprice.mul(2300); // calculate eth transfer cost;
        require(_toBeneficiary >= minEthDonation + _transferCost, "VINFTS: INSUFFICIENT AMOUNT FOR DONATION");
        payable(_beneficiary).transfer(_toBeneficiary);
        payable(VITreasury).transfer(msg.value.sub(_toBeneficiary));
        purchaseData memory entry = purchaseData(
            block.timestamp,
            msg.sender,
            _beneficiary,
            msg.value
        );
        allPurchases.push(entry);
        userPurchases[msg.sender].push(entry);
    }


    function rePurchaseToken(address _beneficiary, address _artist, uint _artistPercentage) public payable {
        uint _toBeneficiary = msg.value.mul(100-VIRoyalty-_artistPercentage).div(100); // calculate amount will be sent to beneficiary;
        uint _transferCost = tx.gasprice.mul(2300); // calculate eth transfer cost;
        require(_toBeneficiary >= minEthDonation + _transferCost, "VINFTS: INSUFFICIENT AMOUNT FOR DONATION");
        uint _toTreasury = msg.value.mul(VIRoyalty).div(100);
        uint _toArtist = msg.value.mul(_artistPercentage).div(100);
        
        payable(_beneficiary).transfer(_toBeneficiary);
        payable(VITreasury).transfer(_toTreasury);
        payable(_artist).transfer(_toArtist);

        rePurchaseData memory entry = rePurchaseData(
            block.timestamp,
            msg.sender,
            _beneficiary,
            msg.value,
            _artist,
            _artistPercentage
        );
        allRePurchases.push(entry);
        userRePurchases[msg.sender].push(entry);
    }

    receive() external payable {

    }
}