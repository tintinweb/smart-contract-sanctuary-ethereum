// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./external/AggregatorV3Interface.sol";
import "./DiamondContract.sol";


interface IStoreAirdrop {
    function airdrop(
        address _nftContractAddress,
        uint64 _tier, // For random the design
        address _repicient
    )
        external
        payable;
}

contract ShibafriendAirdrop is Initializable, OwnableUpgradeable {
    uint256 public lockDuration; // in second
    uint256 public airdropPrice; // in USD
    uint256 public airdropAmount;
    bool public inAirdrop;
    uint256 public airdropCount; // count of sold airdrop
    AggregatorV3Interface internal bnbPriceFeed;
    IDiamond public diamondContract;
    address public shibaNFTContract;
    uint64 nftTier;
    IStoreAirdrop storeContract;

    mapping (address => bool) public boughtAirdrop;

    function initialize(address _diamondContract, address _shibaNFTContract, address _storeContract) public initializer {
        __Ownable_init_unchained();
        diamondContract = IDiamond(_diamondContract);
        shibaNFTContract = _shibaNFTContract;
        storeContract = IStoreAirdrop(_storeContract);
    }

    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) external onlyOwner() {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"Airdrop: Incorrect Feed");
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function startAirdrop(uint256 _airdropAmount, uint256 _airdropPrice, uint64 _nftTier, uint256 _lockDuration) external onlyOwner() {
        require(_airdropPrice > 0, "Airdrop: Airdrop price must be > 0");
        require(_airdropAmount > 0, "Airdrop: Airdrop amount must be > 0");
        require(_lockDuration > 0, "Airdrop: lock duration must be > 0");

        airdropPrice = _airdropPrice;
        airdropAmount = _airdropAmount;
        lockDuration = _lockDuration;
        nftTier = _nftTier;
        inAirdrop = true;
    }

    function getLatestPrice() public view returns (uint) {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "Airdrop: Invalid price");
        return uint(price) * airdropPrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    function stopAirdrop() external onlyOwner() {
        inAirdrop = false;
    }

    function airdrop() external payable {
        require(inAirdrop, 'Airdrop: Not in airdrop');
        require(!boughtAirdrop[msg.sender], 'Airdrop: Already bought airdrop');
        require(diamondContract.balanceOf(address(this)) >= airdropAmount, 'Airdrop: No more token for airdrop');
        require(msg.value >= getLatestPrice(), "Airdrop: Not enough BNB");

        boughtAirdrop[msg.sender] = true;
        diamondContract.lockTransfer(msg.sender, lockDuration);
        diamondContract.transfer(msg.sender, airdropAmount);
        storeContract.airdrop(shibaNFTContract, nftTier, msg.sender);
        airdropCount++;
    }

    function withdraw() external onlyOwner() {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send BNB");
    }

    function withdrawDiamond() external onlyOwner() {
        diamondContract.transfer(msg.sender, diamondContract.balanceOf(address(this)));
    }

    function changeStoreContract(address _storeContract) external onlyOwner(){
        storeContract = IStoreAirdrop(_storeContract);
    }

    function changeNFTContract(address _shibaNFTContract) external onlyOwner(){
        shibaNFTContract = _shibaNFTContract;
    }

    function setNftTier(uint64 _tier) external onlyOwner(){
        nftTier = _tier;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface AggregatorV3Interface {
    function decimals()
        external
        view
        returns (
            uint8
        );

    function description()
        external
        view
        returns (
            string memory
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

interface IDiamond {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function lockTransfer(address _address, uint256 _lockDuration) external;
}

contract Diamond is IDiamond, Initializable, ContextUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct FeeTier {
        uint256 taxFee;
        uint256 burnFee;
    }

    struct FeeValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tBurn;
    }

    struct tFeeValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tBurn;
    }

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => uint256) private _accountsTier;
    // lock for airdrop
    mapping (address => uint256) private transferLockTime;
    EnumerableSetUpgradeable.AddressSet private allowedLockReceivers;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private _maxFee;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    FeeTier public _defaultFees;
    FeeTier private _previousFees;
    FeeTier private _emptyFees;

    FeeTier[] private feeTiers;

    address private _initializerAccount;
    address public _burnAddress;

    uint256 public _maxTxAmount;

    bool private _upgraded;
    bytes32 public constant TRANSFER_LOCKER = keccak256("TRANSFER_LOCKER");
    modifier lockUpgrade {
        require(!_upgraded, "Diamond: Already upgraded");
        _;
        _upgraded = true;
    }

    modifier checkTierIndex(uint256 _index) {
        require(feeTiers.length > _index, "Diamond: Invalid tier index");
        _;
    }

    modifier preventBlacklisted(address _account, string memory errorMsg) {
        require(!_isBlacklisted[_account], errorMsg);
        _;
    }

    /**
      @dev check for lock transfer
    */
    modifier preventLocked(address _from, address _to) {
        // release lock
        if (transferLockTime[_from] > 0 && transferLockTime[_from] < block.timestamp) {
            transferLockTime[_from] = 0;
        }

        require((transferLockTime[_from] == 0) || allowedLockReceivers.contains(_to), "Diamond: Wallet is locked");
        _;
    }

    function initialize() public initializer {
        console.log('Initializing..');
        __Context_init_unchained();
        console.log('Context done');
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        console.log('Access Control done');
        __Diamond_init_unchained();
        console.log('Diamond done');
    }

    function __Diamond_init_unchained() internal initializer {
        _name = "ShibafriendNFT Diamond";
        _symbol = "DIAMOND";
        _decimals = 0;

        _tTotal = 10 ** 30;
        _rTotal = (MAX - (MAX % _tTotal));
        _maxFee = 5000;

        _maxTxAmount = _tTotal / 100;

        _burnAddress = 0x000000000000000000000000000000000000dEaD;
        _initializerAccount = _msgSender();

        _rOwned[_initializerAccount] = _rTotal;

        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;

        __Diamond_tiers_init();

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function __Diamond_tiers_init() internal initializer {
        _defaultFees = _addTier(0, 500);
        _addTier(2500, 2500);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account] || account == _burnAddress) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function lockTransfer(address _address, uint256 _lockDuration) external override{
        require(hasRole(TRANSFER_LOCKER , msg.sender) || hasRole(DEFAULT_ADMIN_ROLE,msg.sender), 'Diamond: Not allowed');
        transferLockTime[_address] = block.timestamp + _lockDuration;
    }

    function getTransferLockTime() public view returns (uint256) {
        return transferLockTime[_msgSender()];
    }

    function allowLockReceiver(address _add) external onlyAdmin() {
        allowedLockReceivers.add(_add);
    }

    function removeLockReceiver(address _add) external onlyAdmin() {
        allowedLockReceivers.remove(_add);
    }

    function getAllowedLockReceivers() external view returns (address[] memory) {
        return allowedLockReceivers.values();
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromTokenInTiers(uint256 tAmount, uint256 _tierIndex, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            FeeValues memory _values = _getValues(tAmount, _tierIndex);
            return _values.rAmount;
        } else {
            FeeValues memory _values = _getValues(tAmount, _tierIndex);
            return _values.rTransferAmount;
        }
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        return reflectionFromTokenInTiers(tAmount, 0, deductTransferFee);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyAdmin() {
        if (!_isExcluded[account]) {
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        }
    }

    function includeInReward(address account) external onlyAdmin() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyAdmin() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyAdmin() {
        _isExcludedFromFee[account] = false;
    }

    function whitelistAddress(
        address _account,
        uint256 _tierIndex
    )
    public
    onlyAdmin()
    checkTierIndex(_tierIndex)
    preventBlacklisted(_account, "Diamond: Selected account is in blacklist")
    {
        require(_account != address(0), "Diamond: Invalid address");
        _accountsTier[_account] = _tierIndex;
    }

    function excludeWhitelistedAddress(address _account) public onlyAdmin() {
        require(_account != address(0), "Diamond: Invalid address");
        require(_accountsTier[_account] > 0, "Diamond: Account is not in whitelist");
        _accountsTier[_account] = 0;
    }

    function accountTier(address _account) public view returns (FeeTier memory) {
        return feeTiers[_accountsTier[_account]];
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return _accountsTier[_account] > 0;
    }

    function checkFees(FeeTier memory _tier) internal view returns (FeeTier memory) {
        uint256 _fees = _tier.taxFee + _tier.burnFee;
        require(_fees <= _maxFee, "Diamond: Fees exceeded max limitation");

        return _tier;
    }

    function checkFeesChanged(FeeTier memory _tier, uint256 _oldFee, uint256 _newFee) internal view {
        uint256 _fees = _tier.taxFee
            + _tier.burnFee
            - _oldFee
            + _newFee;

        require(_fees <= _maxFee, "Diamond: Fees exceeded max limitation");
    }

    function setTaxFeePercent(uint256 _tierIndex, uint256 _taxFee) external onlyAdmin() checkTierIndex(_tierIndex) {
        FeeTier memory tier = feeTiers[_tierIndex];
        checkFeesChanged(tier, tier.taxFee, _taxFee);
        feeTiers[_tierIndex].taxFee = _taxFee;
        if(_tierIndex == 0) {
            _defaultFees.taxFee = _taxFee;
        }
    }

    function setBurnFeePercent(uint256 _tierIndex, uint256 _burnFee) external onlyAdmin() checkTierIndex(_tierIndex) {
        FeeTier memory tier = feeTiers[_tierIndex];
        checkFeesChanged(tier, tier.burnFee, _burnFee);
        feeTiers[_tierIndex].burnFee = _burnFee;
        if(_tierIndex == 0) {
            _defaultFees.burnFee = _burnFee;
        }
    }

    function addTier(
        uint256 _taxFee,
        uint256 _burnFee
    ) public onlyAdmin() {
        _addTier(
            _taxFee,
            _burnFee
        );
    }

    function _addTier(
        uint256 _taxFee,
        uint256 _burnFee
    ) internal returns (FeeTier memory) {
        FeeTier memory _newTier = checkFees(FeeTier(
                _taxFee,
                _burnFee
            ));
        feeTiers.push(_newTier);

        return _newTier;
    }

    function feeTier(uint256 _tierIndex) public view checkTierIndex(_tierIndex) returns (FeeTier memory) {
        return feeTiers[_tierIndex];
    }

    function blacklistAddress(address account) public onlyAdmin() {
        _isBlacklisted[account] = true;
        _accountsTier[account] = 0;
    }

    function unBlacklistAddress(address account) public onlyAdmin() {
        _isBlacklisted[account] = false;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyAdmin() {
        _maxTxAmount = _tTotal * maxTxPercent / (10 ** 4);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount, uint256 _tierIndex) private view returns (FeeValues memory) {
        tFeeValues memory tValues = _getTValues(tAmount, _tierIndex);
        uint256 tTransferFee = tValues.tBurn;
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tValues.tFee, tTransferFee, _getRate());
        return FeeValues(rAmount, rTransferAmount, rFee, tValues.tTransferAmount, tValues.tFee, tValues.tBurn);
    }

    function _getTValues(uint256 tAmount, uint256 _tierIndex) private view returns (tFeeValues memory) {
        FeeTier memory tier = feeTiers[_tierIndex];
        tFeeValues memory tValues = tFeeValues(
            0,
            calculateFee(tAmount, tier.taxFee),
            calculateFee(tAmount, tier.burnFee)
        );

        tValues.tTransferAmount = tAmount - tValues.tFee - tValues.tBurn;
        return tValues;
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTransferFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferFee = tTransferFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rTransferFee;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if(_fee == 0) return 0;
        return _amount * _fee / (10 ** 4);
    }

    function removeAllFee() private {
        _previousFees = feeTiers[0];
        feeTiers[0] = _emptyFees;
    }

    function restoreAllFee() private {
        feeTiers[0] = _previousFees;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isBlacklisted(address account) public view returns(bool) {
        return _isBlacklisted[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
    private
    preventBlacklisted(owner, "Diamond: Owner address is blacklisted")
    preventBlacklisted(spender, "Diamond: Spender address is blacklisted")
    preventLocked(owner, spender)
    {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
    private
    preventBlacklisted(_msgSender(), "Diamond: Address is blacklisted")
    preventBlacklisted(from, "Diamond: From address is blacklisted")
    preventBlacklisted(to, "Diamond: To address is blacklisted")
    preventLocked(from, to)
    {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!hasRole(DEFAULT_ADMIN_ROLE , from) && !hasRole(DEFAULT_ADMIN_ROLE , to))
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        uint256 tierIndex = 0;

        if(takeFee) {
            tierIndex = _accountsTier[from];

            if(_msgSender() != from) {
                tierIndex = _accountsTier[_msgSender()];
            }
        }

        //transfer amount, it will take tax, burn
        _tokenTransfer(from, to, amount, tierIndex, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 tierIndex, bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, tierIndex);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, tierIndex);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, tierIndex);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, tierIndex);
        } else {
            _transferStandard(sender, recipient, amount, tierIndex);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, uint256 tierIndex) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - _values.rAmount;
        _tOwned[recipient] = _tOwned[recipient] + _values.tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
        _takeBurn(_values.tBurn);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, uint256 tierIndex) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _rOwned[sender] = _rOwned[sender] - _values.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
        _takeBurn(_values.tBurn);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, uint256 tierIndex) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _rOwned[sender] = _rOwned[sender] - _values.rAmount;
        _tOwned[recipient] = _tOwned[recipient] + _values.tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
        _takeBurn(_values.tBurn);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, uint256 tierIndex) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - _values.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
        _takeBurn(_values.tBurn);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _takeBurn(uint256 _amount) private {
        if(_amount == 0) return;
        _tOwned[_burnAddress] = _tOwned[_burnAddress] + _amount;
    }

    function feeTiersLength() public view returns (uint) {
        return feeTiers.length;
    }
    modifier onlyAdmin {
      require(hasRole(DEFAULT_ADMIN_ROLE,msg.sender));
      _;
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DiamondContract.sol";

contract GameContract is AccessControl{
    using SafeMath for uint256;
    using ECDSA for bytes32;

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public SHFTokenAddress;
    Diamond public DiamondTokenAddress;
    address public VaultAddress;
    event UserClaim(uint256 _nonce ,uint256 _rate,uint256 _amount, address claimer);
    struct GameRewards {
        address gamerAddress;
        uint256 claimAmount;
    }
    mapping(bytes32 => GameRewards) public claim;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function setTokenAddress(address _shf, address payable _diamond) public onlyRole(DEFAULT_ADMIN_ROLE) {
        SHFTokenAddress = _shf;
        DiamondTokenAddress = Diamond(_diamond);
    }

    function setVaultAddress(address _vault) public onlyRole(DEFAULT_ADMIN_ROLE){
        VaultAddress = _vault;
    }

    // function mintDiamond(uint256 amount) public onlyRole(MINTER_ROLE){
    //     Diamond(DiamondTokenAddress).mint(address(this), amount);
    // }

    // Get message hash to sign
    function getMessageHash(
        address _gamerAddress,
        uint256 _nonce,
        uint256 _claimAmount,
        uint256 _rate
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_gamerAddress, _nonce, _claimAmount, _rate));
    }

    // claim SFG
    function claimDiamond(
        uint256 _nonce,
        uint256 _claimAmount,
        uint256 _rate,
        bytes memory signature
    ) public {
        bytes32 _hashedNonce = keccak256(abi.encodePacked(_nonce, msg.sender));
        require (!(claim[_hashedNonce].claimAmount > 0), "has claimed");
        // verify signature
        bytes32 messageHash = getMessageHash(msg.sender, _nonce, _claimAmount, _rate);
        require (hasRole(SIGNER_ROLE, messageHash
            .toEthSignedMessageHash()
            .recover(signature)), "signature invalid");

        // transfer token.
        DiamondTokenAddress.transfer(msg.sender, _claimAmount * _rate);
        ERC20(SHFTokenAddress).transferFrom(msg.sender, VaultAddress, _claimAmount);

        claim[_hashedNonce] = GameRewards(msg.sender, _claimAmount);
        emit UserClaim(_nonce,_rate,_claimAmount ,msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Marketplace Contract
 * @notice A contract that allow users place nft to sold
 */
contract SHFMarketplace is AccessControlUpgradeable, PausableUpgradeable {
    /*
        List of nft to be trading on marketplace
    */
    mapping(address => mapping(uint256 => Trading)) public tradings;
    mapping(IERC721 => SpecialFee) public specialFee;
    uint256 public defaultFee;
    mapping(IERC20 => bool) public currencies;
    struct Trading {
        address seller;
        uint256 price;
        uint256 startAt;
        address currency;
    }
    //Repesent the special fee of some nft address
    struct SpecialFee {
        uint256 rate;
        bool enabled;
    }
    // Contract's Events
    event TradingCreated(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _price,
        address indexed _seller,
        address _currency
    );

    event TradingSuccessful(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _price,
        address indexed _buyer,
        address _currency
    );

    event TradingCancelled(
        address indexed _nftAddress,
        uint256 indexed _tokenId
    );

    function initialize(uint256 _defaultFee) initializer public {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(_defaultFee <= 100, "This fee is not acceptable");
        require(_defaultFee >= 0, "This fee is not acceptable");
        defaultFee = _defaultFee;
    }

    /*
        Admin functions
    */
    function setSpecialFee(address externalNftAddress, uint256 fee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(fee <= 100, "This fee is not acceptable");
        require(fee >= 0, "This fee is not acceptable");
        // Set the fee
        specialFee[IERC721(externalNftAddress)] = SpecialFee(fee, true);
    }

    function removeSpecialFee(address externalNftAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Set the fee
        // specialFee[externalNftAddress].rate = 0;
        delete specialFee[IERC721(externalNftAddress)];
    }

    function setDefaultFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 100, "This fee is not acceptable");
        require(fee >= 0, "This fee is not acceptable");
        // Set the fee
        defaultFee = fee;
    }

    function addCurrency(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        currencies[IERC20(currencyAddress)] = true;
    }

    function removeCurrency(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delete currencies[IERC20(currencyAddress)];
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        End admin functions
    */

    /*
       @dev check if a token is on sale
    */
    modifier isOnTrading(address _nftAddress, uint256 _tokenId) {
        require(tradings[_nftAddress][_tokenId].startAt > 0, "Token not listed for sale");
        _;
    }

    /*
        @dev Creates and begins a new trade. sender should already allow this contract to manage _tokenId
        @param _nftAddress - address of a deployed contract implementing NFT interface.
        @param _tokenId - ID of token to trade, sender must be owner.
        @param _price - price to trade
    */
    function createTrading(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        address _currency
    ) external whenNotPaused {
        address _seller = msg.sender;
        require(_price >= 100, "Must set a price");
        require(_price % 100 == 0, "Price must be divisible by 100");
        // currency must be native token or allowed
        require((_currency == address(0)) || (currencies[IERC20(_currency)] == true), "Currency not allowed");
        require(_owns(_nftAddress, _seller, _tokenId), "Invalid owner");
        /*
            Transfer the nft to marketplace
        */
        _escrow(_nftAddress, _seller, _tokenId);
        Trading memory _trading = Trading(
            _seller,
            _price,
            block.timestamp,
            _currency
        );
        _addTrading(_nftAddress, _tokenId, _trading, _seller, _currency);
    }

    function buy(address _nftAddress, uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        _buy(_nftAddress, _tokenId);
        _transfer(_nftAddress, msg.sender, _tokenId);
    }

    /// @dev tranfer money too
    ///  Returns the NFT to original owner.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token on trading
    function cancelTrading(address _nftAddress, uint256 _tokenId)
        external
        isOnTrading(_nftAddress, _tokenId)
    {
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        require(msg.sender == _trading.seller);
        _cancelTrading(_nftAddress, _tokenId, _trading.seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the Admin can do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelTradingWhenPaused(address _nftAddress, uint256 _tokenId)
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
        isOnTrading(_nftAddress, _tokenId)
    {
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        _cancelTrading(_nftAddress, _tokenId, _trading.seller);
    }

    function _computeFee(uint256 _price, address _nftAddress)
        internal
        view
        returns (uint256)
    {
        IERC721 _nftContract = IERC721(_nftAddress);
        if (specialFee[_nftContract].enabled) {
            return _price / 100 * specialFee[_nftContract].rate;
        }
        return _price / 100 * defaultFee;
    }

    function _buy(address _nftAddress, uint256 _tokenId)
        internal
        isOnTrading(_nftAddress, _tokenId)
        returns (uint256)
    {
        // Get a reference to the auction struct
        Trading storage _trading = tradings[_nftAddress][_tokenId];

        //Validate trading

        uint256 _price = _trading.price;
        address _seller = _trading.seller;
        address _currency = _trading.currency;

        // Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeTrading(_nftAddress, _tokenId);

        // Transfer proceeds to seller (if there are any!)
        uint256 _tradingFee = _computeFee(_price, _nftAddress);
        uint256 _sellerProceeds = _price - _tradingFee;
        if (_currency == address(0)) {
            require(msg.value >= _price, "Not enough money");
            payable(_seller).transfer(_sellerProceeds);
        } else {
            // client call approve with from buyer
            // then contract call transfer
            // console.log("Buying", _price);
            // console.log("Allowance", IERC20(_currency).allowance(msg.sender, address(this)));
            IERC20(_currency).transferFrom(msg.sender, address(this), _price);
            IERC20(_currency).transfer(_seller, _sellerProceeds);
        }

        emit TradingSuccessful(
            _nftAddress,
            _tokenId,
            _price,
            msg.sender,
            _currency
        );
        return _price;
    }

    /// @dev Adds an _trading to the list of open tradings. Emit TradingCreated event.
    function _addTrading(
        address _nftAddress,
        uint256 _tokenId,
        Trading memory _trading,
        address _seller,
        address _currency
    ) internal {
        tradings[_nftAddress][_tokenId] = _trading;
        emit TradingCreated(
            _nftAddress,
            _tokenId,
            _trading.price,
            _seller,
            _currency
        );
    }

    /// @dev Removes an trading from the list of open tradings.
    /// @param _tokenId - ID of NFT on auction.
    function _removeTrading(address _nftAddress, uint256 _tokenId) internal {
        delete tradings[_nftAddress][_tokenId];
    }

    /// @dev Cancels an trading unconditionally.
    function _cancelTrading(
        address _nftAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        _removeTrading(_nftAddress, _tokenId);
        _transfer(_nftAddress, _seller, _tokenId);
        emit TradingCancelled(_nftAddress, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _nftAddress - The address of the NFT.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(
        address _nftAddress,
        address _receiver,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);
        // It will throw if transfer fails
        _nftContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _nftAddress - The address of the NFT.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);
        // It will throw if transfer fails
        _nftContract.transferFrom(_owner, address(this), _tokenId);
    }

    /*
        Check NFT address belong to
    */
    function _owns(
        address _nftAddress,
        address _requesterAddr,
        uint256 _tokenId
    ) internal view returns (bool) {
        IERC721 _nftContract = IERC721(_nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _requesterAddr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./ShibaFriendNFT.sol";
import "./external/AggregatorV3Interface.sol";

contract SHFStoreETH is AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal shibPriceFeed;
    uint public sftRate;
    uint public sftRateDecimals;

    address public sftAddress;
    address public shibAddress;

    address private managerWallet;

    enum GroupStatus {
        Expired,
        Ongoing
    }

    mapping(string => GroupStatus) public nftGroupStatus;

    uint public rollingPrice;
    uint public totalSold;
    uint public sftReduceRate;

    address public nftContractAddress;

    struct Info {
        address user;
        uint32 code;
        uint32 referrer;

        uint ethEarning;
        uint sftEarning;
        uint shibEarning;
    }
    EnumerableMap.AddressToUintMap private investorsMap;
    mapping(uint32 => Info) private investorDetails;

    uint32[] public affiliateRate;

    uint public bigReward;
    uint public smallReward;

    uint32 private managerRate;

    event SpecialRewardDropped(address _receiver, uint _value, address _currency);
    event Rolling(address _receiver, uint[] _rollingResult, uint _rewardValue);

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        rollingPrice = 5*10**16;
        sftReduceRate = 20;

        sftRateDecimals = 10**4;
        sftRate = 54;           // with usdT

        affiliateRate.push(25);
        affiliateRate.push(15);
        affiliateRate.push(10);

        bigReward = 1000;       // in USDT
        smallReward = 100;      // in USDT

        managerRate = 11;
    }

    /*
     *  BEGIN: Admin's funcitions
    */
    function setRollingPrice(uint _rollingPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_rollingPrice > 0, "SHFStoreETH: Price must be positive");
        rollingPrice = _rollingPrice;
    }

    function setSftReduceRate(uint _sftReduceRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_sftReduceRate >= 0 && _sftReduceRate < 100, "SHFStoreETH: Rate not allowed");
        sftReduceRate = _sftReduceRate;
    }

    function setAffiliateRates(
        uint32 _affiliateRateLv1,
        uint32 _affiliateRateLv2,
        uint32 _affiliateRateLv3
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_affiliateRateLv1 > 0 &&
                _affiliateRateLv2 > 0 &&
                _affiliateRateLv3 > 0
            , "SHFStoreETH: Rates must be positive");
        
        affiliateRate[0] = _affiliateRateLv1;
        affiliateRate[1] = _affiliateRateLv2;
        affiliateRate[2] = _affiliateRateLv3;
    }
    

    function setSpecialRewards(uint _bigReward, uint _smallReward)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_bigReward > 0 &&
                _smallReward > 0
        , "SHFStoreETH: Rewards must be positive");
        bigReward = _bigReward;
        smallReward = _smallReward;
    }

    function allowNFTContract(address _nftContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(IERC1155(_nftContractAddress).supportsInterface(type(IERC1155).interfaceId), "SHFStoreETH: Contract should be IERC1155");
        
        nftContractAddress = _nftContractAddress;
    }

    function setSFTRate(uint _sftRate, uint _sftRateDecimals)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_sftRate > 0 && _sftRateDecimals > 0, "SHFStoreETH: Price must be positive");
        sftRate = _sftRate;
        sftRateDecimals = _sftRateDecimals;
    }

    function setCurrenciesAddress(address _sftAddress, address _shibAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        sftAddress = _sftAddress;
        shibAddress = _shibAddress;
    }

    function setManagerWallet(address _managerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_managerWallet != address(0), "SHFStoreETH: Marketing wallet cannot be address 0");
        managerWallet = _managerWallet;
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }

    function addSale(
        uint32 _numberOfType,
        string memory _groupNamePrefix
        )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(sftAddress != address(0) && shibAddress != address(0), "SHFStoreETH: SFT and SHIB address must be specified");
        require(_numberOfType > 0, "SHFStoreETH: Number of tier should positive");

        ShibaFriendNFT(nftContractAddress).addGroupNFT(_groupNamePrefix, _numberOfType);
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    // "0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61", "SHIB / ETH"
    function setSHIBPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        shibPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(shibPriceFeed.description()), bytes(_description)),"SHFStoreETH: Incorrect Feed");
    }

    // "0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46", "USDT / ETH"
    function setETHPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ethPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(ethPriceFeed.description()), bytes(_description)),"SHFStoreETH: Incorrect Feed");
    }

    /*
     *  END: Admin's funcitions
    */

    // _salePrice in ETH
    function getLatestPrice(uint256 _salePrice, address _currency)
        public
        view
        returns (uint)
    {
        if(_currency == address(0)) {
            return _salePrice;
        }
        else if(_currency == shibAddress) {
            // SHIB / ETH
            ( , int price, , , ) = shibPriceFeed.latestRoundData();     // SHIB / ETH
            require(price > 0, "SHFStoreETH: Invalid price");
            return _salePrice / uint(price) * 10**18;
        }
        else{
            ( , int price, , , ) = ethPriceFeed.latestRoundData();      // USDT / ETH
            uint toUSDT = _salePrice / uint(price);

            return (toUSDT * sftRateDecimals / sftRate)*10**9;
        }
    }

    function roll(
        uint _numberOfRolling,
        address _currency,
        uint32 _code
    )
        external
        payable
    {
        require(_numberOfRolling > 0 && _numberOfRolling < 499, "SHFStoreETH: Number of rolling incorrect");

        if (!investorsMap.contains(msg.sender)) {
            // gen a code for new user
            _createNewAffiliateInformation(msg.sender);
        }
        // add referrer
        if( investorDetails[uint32(investorsMap.get(msg.sender))].referrer == 0 &&
            _code != 0 && isValidCode(_code)) {

            investorDetails[uint32(investorsMap.get(msg.sender))].referrer = _code;
        }

        uint rewardValue = 0;
        
        // nft and reward
        if ((totalSold + _numberOfRolling) % 1000 < totalSold % 1000) {
            totalSold = totalSold + 1;
            ( , int price, , , ) = ethPriceFeed.latestRoundData();      // USDT / ETH
            require(price > 0, "SHFStoreETH: Invalid price");
            _sendSpecialReward(msg.sender, bigReward * uint(price), address(0));
            _numberOfRolling = _numberOfRolling - 1;
            rewardValue = bigReward;
        }
        else if ((totalSold + _numberOfRolling) % 500 < totalSold % 500) {
            totalSold = totalSold + 1;
            _sendSpecialReward(msg.sender, (smallReward * sftRateDecimals / sftRate)*10**9, sftAddress);
            _numberOfRolling = _numberOfRolling - 1;
            rewardValue = smallReward;
        }

        uint[] memory nftID = _mintAndTransferNFT(msg.sender, _numberOfRolling);

        uint256 petSalePrice = _getToken(_numberOfRolling, _currency);

        uint32 refCode = investorDetails[uint32(investorsMap.get(msg.sender))].referrer;
        _distributeCommision(refCode, petSalePrice, _currency);

        emit Rolling(msg.sender, nftID, rewardValue);
    }

    function _getToken(uint _numberOfRolling, address _currency)
        internal
        returns(uint256)
    {
        require((_currency == address(0)) || 
                (_currency == sftAddress) ||
                (_currency == shibAddress), 
                "SHFStoreETH: Currency not allowed");

        uint256 petSalePrice = rollingPrice * _numberOfRolling;

        if (_currency == address(0)) {
            //Native currency
            require(msg.value >= petSalePrice, "SHFStoreETH: Not enough balance");
        } else{
            petSalePrice = getLatestPrice(petSalePrice, _currency);
            if(_currency == sftAddress) {
                petSalePrice = petSalePrice * (100 - sftReduceRate) / 100;
            }
            IERC20(_currency).transferFrom(msg.sender, address(this), petSalePrice);
        }
        return petSalePrice;
    }

    function _mintAndTransferNFT(address _receiver, uint _numberNFT)
        internal
        returns(uint[] memory)
    {
        if (_numberNFT < 3) {
            uint numberNFT = ShibaFriendNFT(nftContractAddress).TotalType();
            uint[] memory rs = new uint[](numberNFT);
            for (uint i = 0; i < _numberNFT; i++) {
                uint idxID = _getOneRandomSaleID(numberNFT, block.timestamp, _receiver, totalSold);
                rs[idxID] = rs[idxID] + 1;

                uint shiPrefix = ShibaFriendNFT(nftContractAddress).NFTGroupPrefixs("shiba");
                if(idxID >= ShibaFriendNFT(nftContractAddress).NumberOfTypeNFT(shiPrefix)) {
                    uint nftID = ShibaFriendNFT(nftContractAddress).NFTGroupPrefixs("shiba") + 
                                (idxID - ShibaFriendNFT(nftContractAddress).NumberOfTypeNFT(shiPrefix));
                    ShibaFriendNFT(nftContractAddress).mint(_receiver, nftID, 1, "");
                }
                else {
                    uint nftID = ShibaFriendNFT(nftContractAddress).NFTGroupPrefixs("shiba") + idxID;
                    ShibaFriendNFT(nftContractAddress).mint(_receiver, nftID, 1, "");
                }
                
                totalSold = totalSold + 1;
                
            }
            return rs;
        }
        else {
            uint[] memory nftIDs = ShibaFriendNFT(nftContractAddress).getAllNFTID();
            (uint[] memory randomNumbers, uint count) = _getRandomSaleIDs(nftIDs.length, block.timestamp, _receiver, totalSold, _numberNFT);
        
            uint[] memory diffIDs = new uint[](count);
            uint[] memory diffCounts = new uint[](count);
            uint diffIdx = 0;
            for(uint i = 0; i < nftIDs.length; i++) {
                if (randomNumbers[i] != 0) {
                    diffIDs[diffIdx] = nftIDs[i];
                    diffCounts[diffIdx] = randomNumbers[i];
                    diffIdx = diffIdx + 1;
                }
            }

            totalSold = totalSold + _numberNFT;

            ShibaFriendNFT(nftContractAddress).mintBatch(_receiver, diffIDs, diffCounts, "");

            return randomNumbers;
        }
    }

    function _getOneRandomSaleID(uint _numberOfType, uint _time, address _receiver, uint _bonusSeed)
        internal
        pure
        returns (uint)
    {
        uint randomHash = uint(keccak256(abi.encodePacked(_time, _receiver, _bonusSeed)));

        uint randomID = randomHash % _numberOfType;
        
        return randomID;
    }

    
    function _getRandomSaleIDs(uint _numberOfType, uint _time, address _receiver, uint _bonusSeed, uint _numberRandom)
        internal
        pure
        returns (uint[] memory, uint)
    {
        uint[] memory rs = new uint[](_numberOfType);
        uint count = 0;

        for(uint i = 0; i < _numberRandom; i++) {
            uint randomHash = uint(keccak256(abi.encodePacked(_time, _receiver, _bonusSeed + i, _numberRandom)));

            uint randomID = randomHash % _numberOfType;

            if(rs[randomID] == 0)
            {
                count = count + 1;      // number of difference NFT IDs
            }
            rs[randomID] = rs[randomID] + 1;
        }
        
        return (rs, count);
    }


    /*
        Referral system
    */

    /*
        Generate an unique code for a user
    */
    function _generateReferralCode(address _user)
        internal
        view
        returns(uint32)
    {
        require(_user != address(0), "SHFStoreETH: cannot generate affiliate code for address zero");

        uint32 refCode = 0;
        string memory input = "";
        do {
            input = string(abi.encodePacked(input, _user));
            uint hashValue = uint(keccak256(abi.encodePacked(input)));
            uint32 range = 0xffffffff;
            refCode = uint32(hashValue % range);
        } while (refCode != 0 && investorDetails[refCode].user != address(0)); // make sure this referral code has not been issued to any user yet

        return uint32(refCode);
    }

    /*
        Create new user's referral information
    */
    function _createNewAffiliateInformation(address _user)
        internal
        returns(uint32)
    {
        uint32 code = _generateReferralCode(_user);
        investorsMap.set(_user, code);
        // add detail
        investorDetails[code].user = _user;
        investorDetails[code].code = code;

        return uint32(investorsMap.get(_user));
    }

    /*
        code validity
    */
    function isValidCode(uint32 _code)
        public
        view
        returns(bool)
    {
        if(_code != 0 && investorDetails[_code].user == address(0)) {
            return false;
        }
        else {
            return true;
        }
    }

    function _distributeCommision(uint32 _code, uint _value, address _currency)
        internal
    {
        // manager
        if (_currency == address(0)) {
            payable(managerWallet).transfer(_value * managerRate / 100);
        }
        else {
            IERC20 currencyContract = IERC20(_currency);
            currencyContract.transfer(managerWallet, _value * managerRate / 100);
        }
        // Affilivate program
        // level 1
        if(_code != 0) {
            _payCommisionAffiliate(_code, _value, _currency, 1);

            // level 2
            uint32 refCodeLv2 = investorDetails[_code].referrer;
            if(refCodeLv2 != 0) {
                _payCommisionAffiliate(refCodeLv2, _value, _currency, 2);

                // level 3
                uint32 refCodeLv3 = investorDetails[refCodeLv2].referrer;
                if(refCodeLv3 != 0) {
                    _payCommisionAffiliate(refCodeLv3, _value, _currency, 3);
                }
            }
        }
    }

    /*
        pay commision to referrer
    */
    function _payCommisionAffiliate(uint32 _referrerCode, uint _price, address _currency, uint128 _affLv)
        internal
    {
        uint rate = affiliateRate[_affLv-1];

        uint amount = _price * rate / 100;
        if (_currency == address(0)) {
            investorDetails[_referrerCode].ethEarning = investorDetails[_referrerCode].ethEarning + amount;
        }
        else if (_currency == sftAddress){
            investorDetails[_referrerCode].sftEarning = investorDetails[_referrerCode].sftEarning + amount;
        }
        else if (_currency == shibAddress){
            investorDetails[_referrerCode].shibEarning = investorDetails[_referrerCode].shibEarning + amount;
        }
    }

    function _sendSpecialReward(address _user, uint _amount, address _currency)
        internal
        nonReentrant
    {
        if(_currency == address(0)) {
            (bool success, ) = address(_user).call{ value: _amount }("");
            require(success, "SHFStoreETH: Reward failed to send");
        }
        else {
            IERC20(sftAddress).transfer(_user, _amount);
        }
        emit SpecialRewardDropped(_user, _amount, _currency);
    }

    function getAffiliateInfor()
        external
        view
        returns(Info memory)
    {
        return _getAffiliateInfor(msg.sender);
    }

    function _getAffiliateInfor(address _user)
        internal
        view
        returns(Info memory)
    {
        Info memory rs = investorDetails[uint32(investorsMap.get(_user))];
        return rs;
    }

    function userClaim(address _currency)
        external
        nonReentrant
    {
        require(investorsMap.get(msg.sender) > 0, "SHFStoreETH: User not join affiliate system");
        Info storage userInfor = investorDetails[uint32(investorsMap.get(msg.sender))];
        if (_currency == address(0)) {
            require(userInfor.ethEarning > 0, "SHFStoreETH: ETH earning too small");
            uint amount = userInfor.ethEarning;
            userInfor.ethEarning = 0;
            (bool success, ) = address(msg.sender).call{ value: amount }("");
            require(success, "SHFStoreETH: Earning failed to send");
        }
        else if(_currency == sftAddress){
            require(userInfor.sftEarning > 0, "SHFStoreETH: SFT earning too small");
            uint amount = userInfor.sftEarning;
            userInfor.sftEarning = 0;
            IERC20(sftAddress).transfer(msg.sender, amount);
        }
        else if(_currency == shibAddress){
            require(userInfor.shibEarning > 0, "SHFStoreETH: SHIB earning too small");
            uint amount = userInfor.shibEarning;
            userInfor.shibEarning = 0;
            IERC20(shibAddress).transfer(msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract ShibaFriendNFT is
    ERC1155PresetMinterPauser
{
    uint[] public IdPrefixs;
    mapping(string => uint) public NFTGroupPrefixs;

    mapping(uint => uint) public NumberOfTypeNFT;

    uint public TotalType;

    constructor(string memory uri) ERC1155PresetMinterPauser(uri) {

    }

    function addGroupNFT(string memory _groupNamePrefix, uint _numberOfType)
        external
    {
        require(hasRole(MINTER_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender())
                , "ShibaFriendNFT: must have minter role to mint");

        require(_numberOfType > 0, "ShibaFriendNFT: Number of type not allow");

        if(NFTGroupPrefixs[_groupNamePrefix] == 0) {
            uint idPrefix = uint256(_stringToBytes32(_groupNamePrefix));
            NFTGroupPrefixs[_groupNamePrefix] = idPrefix;
            IdPrefixs.push(idPrefix);
        }
        else {
            TotalType = TotalType - NumberOfTypeNFT[NFTGroupPrefixs[_groupNamePrefix]];
        }
        NumberOfTypeNFT[NFTGroupPrefixs[_groupNamePrefix]] = _numberOfType;
        TotalType = TotalType + _numberOfType;
    }

    function getAllNFTID()
        external
        view
        returns(uint[] memory)
    {
        uint[] memory rs = new uint[](TotalType);
        uint idx = 0;

        for(uint i = 0; i < IdPrefixs.length; i++) {
            for(uint j = 0; j < NumberOfTypeNFT[IdPrefixs[i]]; j++) {
                rs[idx] = IdPrefixs[i] + j;
                idx = idx + 1;
            }
        }
        return rs;
    }

    function _stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../extensions/ERC1155Burnable.sol";
import "../extensions/ERC1155Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC1155PresetMinterPauser is Context, AccessControlEnumerable, ERC1155Burnable, ERC1155Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../external/AggregatorV3Interface.sol";

contract PriceFeed is AggregatorV3Interface {
    constructor() {}

    function decimals() override external pure returns (uint8) {
        return 18;
    }

    function description() override external pure returns (string memory) {
        return "SHIB / ETH";
    }

    function latestRoundData() override external pure returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            18446744073709552685,
            7288719399,
            1659600014,
            1659600014,
            18446744073709552685
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/AggregatorV3Interface.sol";

/**
 * @title Marketplace Contract
 * @notice A contract that allow users place nft to sold
 */
contract SHFMarketplaceV2 is AccessControlUpgradeable, PausableUpgradeable {
    /*
        List of nft to be trading on marketplace
    */
    mapping(address => mapping(uint256 => Trading)) public tradings;
    mapping(IERC721 => SpecialFee) public specialFee;
    uint256 public defaultFee;
    struct Trading {
        address seller;
        uint256 price;
        uint256 startAt;
    }
    //Repesent the special fee of some nft address
    struct SpecialFee {
        uint256 rate;
        bool enabled;
    }
    // Contract's Events
    event TradingCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller
    );

    event TradingSuccessful(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed buyer,
        address currency
    );

    event TradingCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    AggregatorV3Interface internal bnbPriceFeed;
    address binanceUSD;

    function initialize(uint256 _defaultFee) initializer public {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(_defaultFee <= 100, "This fee is not acceptable");
        require(_defaultFee >= 0, "This fee is not acceptable");
        defaultFee = _defaultFee;
    }

    /*
        Admin functions
    */
    function setSpecialFee(address externalNftAddress, uint256 fee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(fee <= 100, "This fee is not acceptable");
        require(fee >= 0, "This fee is not acceptable");
        // Set the fee
        specialFee[IERC721(externalNftAddress)] = SpecialFee(fee, true);
    }

    function removeSpecialFee(address externalNftAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Set the fee
        // specialFee[externalNftAddress].rate = 0;
        delete specialFee[IERC721(externalNftAddress)];
    }

    function setDefaultFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 100, "This fee is not acceptable");
        require(fee >= 0, "This fee is not acceptable");
        // Set the fee
        defaultFee = fee;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        End admin functions
    */

    /*
       @dev check if a token is on sale
    */
    modifier isOnTrading(address _nftAddress, uint256 _tokenId) {
        require(tradings[_nftAddress][_tokenId].startAt > 0, "Token not listed for sale");
        _;
    }

    /*
        @dev Creates and begins a new trade. sender should already allow this contract to manage _tokenId
        @param _nftAddress - address of a deployed contract implementing NFT interface.
        @param _tokenId - ID of token to trade, sender must be owner.
        @param _price - price to trade
    */
    function createTrading(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external whenNotPaused {
        address _seller = msg.sender;
        // require(_price >= 100, "Must set a price");
        // require(_price % 100 == 0, "Price must be divisible by 100");
        // currency must be native token or allowed
        require(_owns(_nftAddress, _seller, _tokenId), "Invalid owner");
        /*
            Transfer the nft to marketplace
        */
        _escrow(_nftAddress, _seller, _tokenId);
        Trading memory _trading = Trading(
            _seller,
            _price,
            block.timestamp
        );
        _addTrading(_nftAddress, _tokenId, _trading, _seller);
    }

    function buy(address _nftAddress, uint256 _tokenId ,address _currency)
        external
        payable
        whenNotPaused
    {
        _buy(_nftAddress, _tokenId ,_currency);
        _transfer(_nftAddress, msg.sender, _tokenId);
    }

    /// @dev tranfer money too
    ///  Returns the NFT to original owner.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token on trading
    function cancelTrading(address _nftAddress, uint256 _tokenId)
        external
        isOnTrading(_nftAddress, _tokenId)
    {
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        require(msg.sender == _trading.seller);
        _cancelTrading(_nftAddress, _tokenId, _trading.seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the Admin can do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelTradingWhenPaused(address _nftAddress, uint256 _tokenId)
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
        isOnTrading(_nftAddress, _tokenId)
    {
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        _cancelTrading(_nftAddress, _tokenId, _trading.seller);
    }

    function _computeFee(uint256 _price, address _nftAddress)
        internal
        view
        returns (uint256)
    {
        IERC721 _nftContract = IERC721(_nftAddress);
        if (specialFee[_nftContract].enabled) {
            return _price / 100 * specialFee[_nftContract].rate;
        }
        return _price / 100 * defaultFee;
    }

    function _buy(address _nftAddress, uint256 _tokenId ,address _currency)
        internal
        isOnTrading(_nftAddress, _tokenId)
        returns (uint256)
    {
        // Get a reference to the auction struct
        require((_currency == address(0)) || (_currency == binanceUSD), "SHFMarketPlace: Currency not allowed");
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        require(msg.sender != _trading.seller, "SHFMarketPlace: Cannot buy your own");

        //Validate trading
        address _seller = _trading.seller;
         //USD price
        _removeTrading(_nftAddress, _tokenId);
        if (_currency == address(0)) {
            uint256 _price = getLatestPrice(_trading.price);
            // Transfer proceeds to seller (if there are any!)
            uint256 _tradingFee = _computeFee(_price, _nftAddress);
            uint256 _sellerProceeds = _price - _tradingFee;
            require(msg.value >= _price, "Not enough money");
            payable(_seller).transfer(_sellerProceeds);
        } else {
            uint256 _price = _trading.price * 10**18;
            // Case busd
            uint256 _tradingFee = _computeFee(_price, _nftAddress); // With decimal
            uint256 _sellerProceeds = (_price - _tradingFee); // with decimal
            IERC20(_currency).transferFrom(msg.sender, address(this), _price);
            IERC20(_currency).transfer(_seller, _sellerProceeds);
        }
        emit TradingSuccessful(
            _nftAddress,
            _tokenId,
            _trading.price,
            msg.sender,
            _currency
        );
        return _trading.price;
    }

    /// @dev Adds an _trading to the list of open tradings. Emit TradingCreated event.
    function _addTrading(
        address _nftAddress,
        uint256 _tokenId,
        Trading memory _trading,
        address _seller
    ) internal {
        tradings[_nftAddress][_tokenId] = _trading;
        emit TradingCreated(
            _nftAddress,
            _tokenId,
            _trading.price,
            _seller
        );
    }

    /// @dev Removes an trading from the list of open tradings.
    /// @param _tokenId - ID of NFT on auction.
    function _removeTrading(address _nftAddress, uint256 _tokenId) internal {
        delete tradings[_nftAddress][_tokenId];
    }

    /// @dev Cancels an trading unconditionally.
    function _cancelTrading(
        address _nftAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        _removeTrading(_nftAddress, _tokenId);
        _transfer(_nftAddress, _seller, _tokenId);
        emit TradingCancelled(_nftAddress, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _nftAddress - The address of the NFT.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(
        address _nftAddress,
        address _receiver,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);
        // It will throw if transfer fails
        _nftContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _nftAddress - The address of the NFT.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);
        // It will throw if transfer fails
        _nftContract.transferFrom(_owner, address(this), _tokenId);
    }

    /*
        Check NFT address belong to
    */
    function _owns(
        address _nftAddress,
        address _requesterAddr,
        uint256 _tokenId
    ) internal view returns (bool) {
        IERC721 _nftContract = IERC721(_nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _requesterAddr);
    }

    function setBUSDCurrency(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        binanceUSD = currencyAddress;
    }

    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"SHFMarketPlace: Incorrect Feed");
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool) {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function getLatestPrice(uint256 salePrice) public view returns (uint) {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "SHFMarketPlace: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Staking Contract
*/
contract SHFStaking is AccessControlUpgradeable, PausableUpgradeable{
    //Using safemath
    using SafeMath for uint256;

    address public tokenAddress;

    enum StakePlanStatus{ WITHDREW, IN_PROGRESS }
    enum PlanStatus{ INACTIVE, ACTIVE }
    //Stakes Mapping
    /*
        userStakes[address] => array
    */
    mapping(address => StakePlan[]) public userStakes;
    ContractPlan[] public contractPlans;

    struct StakePlan {
        uint256 amount;
        uint256 planId;
        StakePlanStatus status;
        uint256 stakeTime;
        uint256 dueTime;
    }

    struct ContractPlan {
        uint256 period; // minutes
        PlanStatus status;
        uint256 rate;
        uint256 minimumAmount; // Minimum of token to be staked
        uint256 maximumAmount; // Maximum amount of token to be staked
        uint256 stakedAmount; // Amount of staked tokens
    }

    // Contract's Events
    event Stake(address indexed sender, uint256 amount , uint256 planId);
    // Contract's Events
    event WithDraw(address indexed sender, uint256 amount , uint256 stakeId);

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

    }

    /*
        admin's functions
    */
    function setTokenAddress(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _currency;
    }

    function addPlan(uint256 period, uint256 rate , uint256 minimumAmount , uint256 maximumAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAddress != address(0), "SHFStaking: Token must be specified");
        require(period > 0 , "SHFStaking: Plan period should be positive");
        require(rate > 0 , "SHFStaking: Plan interest should be positive");
        require(minimumAmount >= 0 , "SHFStaking: Plan minimum should be positive");
        require(maximumAmount >= minimumAmount , "SHFStaking: Plan minimum should smaller than maximum");

        uint256 maximumWithInterest = maximumAmount.mul(rate).div(100);

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), maximumWithInterest);
        contractPlans.push(ContractPlan(period, PlanStatus.ACTIVE, rate , minimumAmount, maximumAmount, 0));
    }

    function deactivePlan(uint256 planId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(contractPlans[planId].status == PlanStatus.ACTIVE, "SHFStaking: Plan not found");
        contractPlans[planId].status = PlanStatus.INACTIVE;
    }

    function activePlan(uint256 planId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(contractPlans[planId].status == PlanStatus.INACTIVE, "SHFStaking: Plan not found");
        contractPlans[planId].status = PlanStatus.ACTIVE;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        User's functions
    */
    /**
    * @notice Stake method that update the user's balance
    */
    function stake(uint256 planId, uint256 tokenAmount)
        external
    {

        require(contractPlans[planId].status == PlanStatus.ACTIVE, "SHFStaking: This plan is not acceptable");
        require(contractPlans[planId].minimumAmount <= tokenAmount, "SHFStaking: This plan is not acceptable");
        require(contractPlans[planId].maximumAmount >= contractPlans[planId].stakedAmount.add(tokenAmount), "SHFStaking: Staking amount reached limit");

        // get tokens from sender
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        contractPlans[planId].stakedAmount = contractPlans[planId].stakedAmount.add(tokenAmount);

        // Generate new stake plan with id is the index in
        uint256 stakeTime;
        uint256 dueTime;
        stakeTime = block.timestamp;
        dueTime = stakeTime.add(contractPlans[planId].period * 1 minutes);

        userStakes[msg.sender].push(StakePlan(tokenAmount, planId, StakePlanStatus.IN_PROGRESS , stakeTime, dueTime));

        // emit the event to notify the blockchain that we have correctly Staked some fund for the user
        emit Stake(msg.sender, tokenAmount , planId);
    }

    /**
    * @notice Allow users to withdraw their staked amount from the contract
    */
    function withdraw(uint256 stakeId)
        external
    {
        // check if the user has balance to withdraw
        require(userStakes[msg.sender][stakeId].amount > 0, "SHFStaking: You don't have balance to withdraw");
        require(userStakes[msg.sender][stakeId].status == StakePlanStatus.IN_PROGRESS , "SHFStaking: Cannot withdraw again");
        // Check stake plan can withdraw
        require(isWithdrawAble(stakeId) == true, "SHFStaking: Stake plan still in locktime");

        uint256 stakeAmount;
        uint256 withdrawAmount;
        uint256 interest;

        stakeAmount = userStakes[msg.sender][stakeId].amount;
        // Change stake status to withdrew
        userStakes[msg.sender][stakeId].status = StakePlanStatus.WITHDREW;

        // Calculate the interest
        interest = calculateInterest(stakeId);
        withdrawAmount = stakeAmount.add(interest);
        //Transfer balance back to the user
        require(IERC20(tokenAddress).transfer(msg.sender,withdrawAmount), "SHFStaking: Failed to send user balance back to the user");
        emit WithDraw(msg.sender, withdrawAmount , stakeId);
    }

    function calculateInterest(uint256 stakeId)
        public
        view
        returns(uint)
    {
        uint256 planId;
        planId = userStakes[msg.sender][stakeId].planId;
        return userStakes[msg.sender][stakeId].amount.mul(contractPlans[planId].rate).div(100);
    }

    function isWithdrawAble(uint256 stakeId)
        public
        view
        returns(bool)
    {
        if(userStakes[msg.sender][stakeId].dueTime <= block.timestamp){
            return true;
        }
        return false;
    }

    function totalPlan()
        public
        view
        returns(uint256)
    {
        return contractPlans.length;
    }

    function _userStake(address _user)
        internal
        view
        returns(StakePlan[] memory)
    {
        StakePlan[] memory ret = new StakePlan[](userStakes[_user].length);
        for (uint i = 0; i < userStakes[_user].length; i++) {
            ret[i] = userStakes[_user][i];
        }
        return ret;
    }

    function adminGetUserStake(address _user)
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(StakePlan[] memory)
    {
        return _userStake(_user);
    }

    function userStake()
        public
        view
        returns(StakePlan[] memory)
    {
        return _userStake(msg.sender);
    }

    function getAllPlans()
        public
        view
        returns (ContractPlan[] memory)
    {
        ContractPlan[] memory ret = new ContractPlan[](contractPlans.length);
        for (uint i = 0; i < contractPlans.length; i++) {
            ret[i] = contractPlans[i];
        }
        return ret;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Staking Contract
*/
contract SHFStakingETH is AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable{
    using EnumerableSet for EnumerableSet.AddressSet;
    enum StakeStatus{ WITHDREW, IN_PROGRESS }

    bytes32 public constant PRIVATE_SALE_ROLE = keccak256("PRIVATE_SALE_ROLE");
    bytes32 public constant GAME_POOL_ROLE = keccak256("GAME_POOL_ROLE");

    struct RoundInfo {
        uint256 id;
        uint256 planStakedAmount;
        uint256 totalReward;
    }

    struct UserStakingInfo {
        address user;
        uint256 stakedAmount;
        uint256 startRoundID;
        StakeStatus status;
    }

    address public tokenAddress;

    uint256 private totalStakedAmount;

    RoundInfo [] public rewardRounds;

    EnumerableSet.AddressSet private investors;

    mapping(address => UserStakingInfo[]) public investorDetails;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();
    }

    /*
        admin's functions
    */
    function setTokenAddress(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _currency;
    }

    function distributeTokenReward(uint256 _totalReward)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_totalReward > 0, "SHFStaking: Reward must be greater than 0.");

        require(msg.value >= _totalReward, "SHFStaking: Not enough balance.");

        uint256 id = rewardRounds.length;

        rewardRounds.push(RoundInfo(id, totalStakedAmount, _totalReward));
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_currency == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currency);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        User's functions
    */

    /*
        Stake function of user
    */
    function userStake(uint256 tokenAmount)
        external
    {
        _stake(msg.sender, tokenAmount);
    }

    /*
        Stake function of contract: Private sale send tokens to stake for a user
    */
    function contractStake(address _user, uint256 _tokenAmount)
        external
    {
        require(hasRole(PRIVATE_SALE_ROLE, msg.sender), "SHFStaking: Caller is not Private Sale");
        _stake(_user, _tokenAmount);
    }

    /**
    * @notice Stake method that update the user's balance
    * @notice Staking will start in next Round
    */
    function _stake(address _user, uint256 _tokenAmount)
        internal
    {
        require(_user != address(0), "SHFStaking: Address Zero cannot stake.");
        require(_tokenAmount > 0, "SHFStaking: Amount of token must be greater than 0.");

        // get tokens from sender
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        
        // update total stacked token of contract
        totalStakedAmount = totalStakedAmount + _tokenAmount;
        
        // add _user to list of investors
        if(!investors.contains(_user)) {
            investors.add(_user);
        }

        // Add another staking to _user
        uint256 nextRound = rewardRounds.length;

        investorDetails[_user].push(UserStakingInfo(_user, _tokenAmount, nextRound, StakeStatus.IN_PROGRESS));
    }

    /**
    * @notice Allow users to withdraw their staked amount from the contract
    */
    function withdraw()
        external
    {
        _sendToken(msg.sender);
        if(_calculateReward(msg.sender) > 0) {
            _sendReward(msg.sender);
        }
        _closeStakingUser(msg.sender);
    }

    function _sendToken(address _user)
        internal
    {
        require(_user != address(0), "SHFStaking: Cannot send token to address zero.");

        uint amountToken = _calculateStakedToken(_user);

        require(amountToken > 0, "SHFStaking: Amount of token too small.");

        IERC20(tokenAddress).transfer(_user, amountToken);

        totalStakedAmount = totalStakedAmount - amountToken;
    }

    function _closeStakingUser(address _user)
        internal
    {
        for(uint i = 0; i < investorDetails[_user].length; i++) {
            if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                investorDetails[_user][i].status = StakeStatus.WITHDREW;
                
            } 
        }
    }

    function calculateStakedToken()
        external
        view
        returns(uint)
    {
        return _calculateStakedToken(msg.sender);
    }

    function _calculateStakedToken(address _user)
        internal
        view
        returns(uint)
    {
        uint stakedToken = 0;

        for(uint i = 0; i < investorDetails[_user].length; i++) {
            if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                stakedToken = stakedToken + investorDetails[_user][i].stakedAmount;
            } 
        }

        return stakedToken;
    }

    /*
        User claim his reward without withdraw token
    */
    function claimReward()
        public
    {
        _sendReward(msg.sender);
        _changeStartRound(msg.sender);
    }

    function _sendReward(address _user)
        internal
        nonReentrant
    {
        require(_user != address(0), "SHFStaking: Cannot send reward to address zero.");

        uint reward = _calculateReward(_user);

        require(reward > 0, "SHFStaking: Reward too small.");

        // DO NOT use transfer because reentrancy attacks
        // payable(_user).transfer(reward);
        (bool success, ) = address(_user).call{ value: reward }("");

        require(success, "SHFStaking: Reward failed to send");
    }

    function _changeStartRound(address _user)
        internal
    {
        for(uint i = 0; i < investorDetails[_user].length; i++) {
            if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                investorDetails[_user][i].startRoundID = rewardRounds.length;
            } 
        }
    }
    
    function calculateReward()
        external
        view
        returns(uint)
    {
        return _calculateReward(msg.sender);
    }

    function _calculateReward(address _user)
        internal
        view
        returns(uint)
    {
        uint reward = 0;
        
        if(investors.contains(_user)) {
            uint currentRound = rewardRounds.length - 1;
            for(uint i = 0; i < investorDetails[_user].length; i++) {
                if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                    for(uint j = investorDetails[_user][i].startRoundID; j <= currentRound; j++) {
                        uint totalRw = rewardRounds[j].totalReward;
                        uint userAmount = investorDetails[_user][i].stakedAmount;
                        uint totalAmount = rewardRounds[j].planStakedAmount;

                        uint roundReward = totalRw * userAmount / totalAmount;

                        reward = reward + roundReward;
                    }
                } 
            }
        }
        
        return reward;
    }

    function _userGetStake(address _user)
        internal
        view
        returns(UserStakingInfo[] memory)
    {
        UserStakingInfo[] memory ret = new UserStakingInfo[](investorDetails[_user].length);
        for (uint i = 0; i < investorDetails[_user].length; i++) {
            ret[i] = investorDetails[_user][i];
        }
        return ret;
    }

    function adminGetUserStake(address _user)
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(UserStakingInfo[] memory)
    {
        return _userGetStake(_user);
    }

    function userGetStake()
        public
        view
        returns(UserStakingInfo[] memory)
    {
        return _userGetStake(msg.sender);
    }

    function getAllRounds()
        public
        view
        returns (RoundInfo[] memory)
    {
        RoundInfo[] memory ret = new RoundInfo[](rewardRounds.length);
        for (uint i = 0; i < rewardRounds.length; i++) {
            ret[i] = rewardRounds[i];
        }
        return ret;
    }
}

// contracts/TestERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ShibaFriend is ERC20, AccessControl, ReentrancyGuard {
    uint8 private _decimals = 9;

    using EnumerableSet for EnumerableSet.AddressSet;

    bool private _isAllowWalletTransfer;

    EnumerableSet.AddressSet private _blacklisted;

    EnumerableSet.AddressSet private _allowedSend;

    EnumerableSet.AddressSet private _allowedReceive;

    constructor(uint256 initialSupply) ERC20("SHIBAFRIEND NFT", "SFT") ReentrancyGuard() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _mint(msg.sender, initialSupply  * 10**_decimals);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
    */
    function _transfer(address from, address to, uint256 amount)
        internal
        nonReentrant
        override
    {
        // sender and receiver must not be in blacklisted.
        require(!isBlacklisted(from) && !isBlacklisted(to), "ShibaFriend: sender or receiver is blacklisted");

        // when wallet transfer is disable, sender or receiver must be in allowed contract list.
        if(!_isAllowWalletTransfer) {
            require(isAllowSend(from) || isAllowReceive(to), "ShibaFriend: sender or receiver not allowed");
        }

        super._transfer(from, to, amount);
    }

    /*
        Additional functions
    */
    function isAllowWalletTransfer()
        external
        view
        returns(bool)
    {
        return _isAllowWalletTransfer;
    }

    function isBlacklisted(address _account)
        public
        view
        returns(bool)
    {
        return _blacklisted.contains(_account);
    }

    function isAllowSend(address _account)
        public
        view
        returns(bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, _account) ||
                _allowedSend.contains(_account);
    }

    function isAllowReceive(address _account)
        public
        view
        returns(bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, _account) ||
                _allowedReceive.contains(_account);
    }

    // Admin's functions

    function allowWalletTransfer()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isAllowWalletTransfer = true;
    }

    function unAllowWalletTransfer()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isAllowWalletTransfer = false;
    }

    function blacklistAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(!_blacklisted.contains(_account)) {
            _blacklisted.add(_account);
        }
    }

    function unBlacklistAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(_blacklisted.contains(_account)) {
            _blacklisted.remove(_account);
        }
    }

    function allowSendAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(!_allowedSend.contains(_account)) {
            _allowedSend.add(_account);
        }
    }

    function unAllowSendAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(_allowedSend.contains(_account)) {
            _allowedSend.remove(_account);
        }
    }

    function allowReceiveAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(!_allowedReceive.contains(_account)) {
            _allowedReceive.add(_account);
        }
    }

    function unAllowReceiveAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(_allowedReceive.contains(_account)) {
            _allowedReceive.remove(_account);
        }
    }

    // statistic functions
    function getBlackListedAddress()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(address[] memory)
    {
        address[] memory wallets = new address[](_blacklisted.length());
        for(uint i = 0; i < _blacklisted.length(); i++) {
            wallets[i] = _blacklisted.at(i);
        }
        return wallets;
    }

    function getAllowedSendAddress()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(address[] memory)
    {
        address[] memory wallets = new address[](_allowedSend.length());
        for(uint i = 0; i < _allowedSend.length(); i++) {
            wallets[i] = _allowedSend.at(i);
        }
        return wallets;
    }

    function getAllowedReceiveAddress()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(address[] memory)
    {
        address[] memory wallets = new address[](_allowedReceive.length());
        for(uint i = 0; i < _allowedReceive.length(); i++) {
            wallets[i] = _allowedReceive.at(i);
        }
        return wallets;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// contracts/TestERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestSHF is ERC20 {
    uint8 private _decimals = 9;

    constructor(uint256 initialSupply) ERC20("SHIBAFRIEND_TEST", "SHFT") {
        _mint(msg.sender, initialSupply  * 10**9);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SHFContract is ERC20 {
    uint8 private _decimals = 9;

    constructor() ERC20("SHIBAFRIEND", "SHFContract") {
    	_mint(msg.sender, 100000000000  * 10**9);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ShibaFriendPet.sol";
import "./external/AggregatorV3Interface.sol";
import "./SHFAffiliate.sol";

contract SHFStore is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.AddressSet private acceptedNFTs;

    enum SaleStatus { Ongoing, Expired }

    struct PetSale {
        address nftContractAddress;
        uint128 price;
        uint64 startedAt;
        SaleStatus status;
        uint64 batchId;
        uint64 tier;
        uint32 limit;
        uint32 bought;
    }
    event SaleCreated(address nftContractAddress, uint256 price, uint64 startedAt, SaleStatus status, uint64 batchId, uint64 tier);
    event SaleEnded(address nftContractAddress, uint64 batchId, uint64 tier);
    // event SaleSuccessful(uint256 indexed _tokenId, uint256 _price);

    PetSale[] PetSales;
    uint256[] private toBeDeleted;

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    AggregatorV3Interface internal bnbPriceFeed;
    address binanceUSD;

    // Affiliate system
    SHFAffiliate private shfAffiliate;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();
    }

    function allowNFTContract(address _nftContractAddress)
        external
        returns(bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(IERC721(_nftContractAddress).supportsInterface(type(IERC721).interfaceId), "SHFStore: Contract should be ERC721");
        return acceptedNFTs.add(_nftContractAddress);
    }

    function disallowNFTContract(address _nftContractAddress)
        external
        returns(bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        return acceptedNFTs.remove(_nftContractAddress);
    }

    function setBUSDCurrency(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        binanceUSD = currencyAddress;
    }

    function setAffiliate(address _shfAffiliate) 
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "DEFI: Caller is not an admin"
        );
        shfAffiliate = SHFAffiliate(_shfAffiliate);
    }

    /*
        @dev This function will mint a pet of a sale with referral code
        Requirements:
        - NFT contract address is allowed
        - saleId is existed
    */
    function buyWithAffiliate(
        address _nftContractAddress,
        uint64 _saleId,
        address _currency,
        uint32 _referrerCode
    )
        external
        payable
    {
        uint256 petSalePrice = _buy(_nftContractAddress, _saleId, _currency);

        // BEGIN: Referral system
        // If _referralCode is good and referrer of user not exist
        if (shfAffiliate.checkReferralCode(_referrerCode) == 0 && !shfAffiliate.hasReferrerTier1ForStore(msg.sender)) {
            shfAffiliate.addReferrer(msg.sender, _referrerCode);
        }
        // Check referral information of user
        if (shfAffiliate.hasReferrerTier1ForStore(msg.sender)) {
            
            uint32 affCodeTier1 = shfAffiliate.getReferrerCodeTier1ForStore(msg.sender);
            _payCommisionReferral(shfAffiliate.getAddressOfCode(affCodeTier1), petSalePrice, _currency, _saleId, shfAffiliate.getEarningRateLv1());

            if (shfAffiliate.hasReferrerTier2ForStore(msg.sender)) {
                uint32 affCodeTier2 = shfAffiliate.getReferrerCodeTier2ForStore(msg.sender);
                _payCommisionReferral(shfAffiliate.getAddressOfCode(affCodeTier2), petSalePrice, _currency, _saleId, shfAffiliate.getEarningRateLv2());
            }
        }
    }

        /*
        @dev This function will mint a pet of a sale with referral code
        Requirements:
        - NFT contract address is allowed
        - saleId is existed
    */
    function _payCommisionReferral(
        address _receiver,
        uint256 _price,
        address _currency,
        uint64 _saleId,
        uint rate
    )
        internal
    {
        uint256 price = _price * rate / 100;
        if (_currency == address(0)) {
            //Native currency
            payable(_receiver).transfer(price);
        } else{
            // IERC20 currency
            IERC20(_currency).transfer(_receiver, price);
        }
        PetSale storage petSale = PetSales[_saleId];

        shfAffiliate.addBuyCommisionHistory(_receiver, petSale.price * rate / 100);
    }

    /*
        @dev This function will mint a pet of a sale
        Requirements:
        - NFT contract address is allowed
        - saleId is existed
    */
    function buy(
        address _nftContractAddress,
        uint64 _saleId,
        address _currency
    )
        external
        payable
    {
        _buy(_nftContractAddress, _saleId, _currency);
    }

    function _buy(
        address _nftContractAddress,
        uint64 _saleId,
        address _currency
    )
        internal
        returns(uint256)
    {
        PetSale storage petSale = PetSales[_saleId];
        require(acceptedNFTs.contains(_nftContractAddress), "SHFStore: contract address not allowed");
        require(petSale.status == SaleStatus.Ongoing, "SHFStore: Sale must be on going");
        require((_currency == address(0)) || (_currency == binanceUSD), "SHFStore: Currency not allowed");
        require(petSale.limit > petSale.bought, "SHFStore: sale reached limit");
        // mint and transfer nft to buyer
        // TODO: Fix rate of ERC20
        uint256 petSalePrice = petSale.price;
        if (_currency == address(0)) {
            //Native currency
            petSalePrice = getLatestPrice(petSale.price);
            require(msg.value >= petSalePrice, "SHFStore: Not enough balance");
        } else{
            // IERC20 currency
            petSalePrice = petSale.price * 10**18;
            IERC20(_currency).transferFrom(msg.sender, address(this), petSalePrice);
        }
        petSale.bought++;
        ShibaFriendPet(_nftContractAddress).mintBuy(msg.sender, petSale.tier,petSale.batchId);

        // End Sale
        if (petSale.bought == petSale.limit) {
            emit SaleEnded(_nftContractAddress, petSale.batchId, petSale.tier);
        }
        return petSalePrice;
    }

    /*
        @dev This function will mint a pet of a sale for airdrop
        Requirements:
        - msg sender will be airdrop
    */
    function airdrop(
        address _nftContractAddress,
        uint64 _tier, // For random the design
        address _repicient
    )
        external
        payable
    {
        require(acceptedNFTs.contains(_nftContractAddress), "SHFStore: contract address not allowed");
        require(
            hasRole(AIRDROP_ROLE, msg.sender),
            "SHFStore: Caller is not an airdroper"
        );
        uint _saleId = getRandomSaleId(_tier);
        ShibaFriendPet(_nftContractAddress).mintBuy(_repicient, PetSales[_saleId].tier,PetSales[_saleId].batchId);
    }

    function getRandomSaleId(uint64 _tier)
        internal
        view
        returns (uint _saleId)
    {
        uint[] memory listSales = new uint[](PetSales.length);
        uint saleLength;
        for (uint i=0; i<PetSales.length; i++) {
           if(PetSales[i].status == SaleStatus.Ongoing && PetSales[i].tier == _tier){
               listSales[saleLength] = i;
               saleLength++;
           }
        }
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, uint(0))));
        uint randomNumber = randomHash % saleLength;
        return listSales[randomNumber];
    }

    function deactiveSale(uint256 saleId ) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(PetSales[saleId].status == SaleStatus.Ongoing, "SHFStore: Sale not found");
        PetSales[saleId].status = SaleStatus.Expired;
    }

    function activeSale(uint256 saleId ) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(PetSales[saleId].status == SaleStatus.Expired, "SHFStore: Sale not found");
        PetSales[saleId].status = SaleStatus.Ongoing;
    }

    function addSale(
        address nftContractAddress,
        uint128 price,
        uint64 batchId,
        uint64 tier,
        uint32 limit
        )
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        require(acceptedNFTs.contains(nftContractAddress), "SHFStore: contract address not allowed");
        require(price > 0, "SHFStore: Price should positive");
        require(tier > 0, "SHFStore: Tier should positive");
        require(batchId > 0, "SHFStore: Batch id should positive");
        require(limit > 0, "SHFStore: Limit buy must greater than 0");

        uint64 _startedAt = uint64(block.timestamp);
        PetSales.push(PetSale(nftContractAddress, price, _startedAt, SaleStatus.Ongoing , batchId, tier, limit, 0));
        emit SaleCreated(nftContractAddress, price, _startedAt, SaleStatus.Ongoing, batchId, tier);
    }

    function getAllSales() public view returns (PetSale[] memory) {
        return PetSales;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFStore: Caller is not an admin"
        );
        // withdraw native currency
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"SHFStore: Incorrect Feed");
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool) {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function getLatestPrice(uint256 salePrice) public view returns (uint) {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "SHFStore: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract ShibaFriendPet is
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable
{
    struct ShibaDetail {
        bytes32 _id;
        uint64 tier;
        uint64 bacthId;
        uint64 minted_at;
    }
    uint64 public lockTime;
    mapping (uint256 => ShibaDetail) public ShibaDetails;
    string public tokenURIPrefix;
    string public tokenURISuffix;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    event MintBuy(address _recipient,bytes32 _shibaId ,uint64 _batchId ,uint64 _tier);
    function initialize() initializer public {
        __ERC721_init_unchained("SHIBANFT", "SHIBANFT");
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        lockTime = 90 days;
        tokenURIPrefix = "https://beta-api.shibafriend.io/pet/";
        tokenURISuffix = "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
       @dev Hook override for ERC721Enumerable
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
    }

    function mintBuy(address _recipient, uint64 _tier ,uint64 _batchId)
        public
    {
        require(
            hasRole(MINTER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ShibaFriendPet: Caller is not a minter"
        );

        bytes32 _shibaId;
        _shibaId = keccak256(abi.encodePacked(_batchId, _tier, block.timestamp, totalSupply()));
        ShibaDetail memory _shiba_detail = ShibaDetail(
                _shibaId,
                _tier,
                _batchId,
                uint64(block.timestamp)
        );
        ShibaDetails[uint(_shibaId)]= _shiba_detail;
         _mint(_recipient, uint(_shibaId));
        emit MintBuy(_recipient,_shibaId ,_batchId ,_tier);

    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {

        require(block.timestamp > (ShibaDetails[tokenId].minted_at + lockTime) ,"SHFNFT: Still in lock time");
        super._transfer(from,to,tokenId);
    }
    function _burn(uint256 _tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        string memory _tokenURI = Strings.toHexString(_tokenId);
        return string(abi.encodePacked(tokenURIPrefix, _tokenURI, tokenURISuffix));
    }

    function setTokenURIAffixes(string memory _prefix, string memory _suffix)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        tokenURIPrefix = _prefix;
        tokenURISuffix = _suffix;
    }

    function getShibaDetail(uint256 _tokenId) public view returns (ShibaDetail memory) {
        return ShibaDetails[_tokenId];
    }
    function setLockTime(uint64 _lockTime)
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ShibaFriendPet: Caller is not an admin"
        );
        lockTime = _lockTime;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./external/AggregatorV3Interface.sol";
import "./SHFStore.sol";
import "./SHFMarketPlace_v2.sol";

contract SHFAffiliate is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    AggregatorV3Interface internal bnbPriceFeed;

    // Referral system
    struct Referral {
        address user;                       // user owns this code
        uint32 referrerCode;                // the referrer code of user which referred this code
        uint256 totalAmount;                // total earnings of this code from buying NFT
        uint256 totalAmountGenRefCode;      // total earnings of this code from generate affiliate code
        uint256 currentAmountGenRefCode;    // claimable earnings of this code from generate affiliate code
        bool isActive;                      // allow user to join earning program
    }
    // Referral code of each user
    mapping(address => uint32) private referralLists;
    // Detail of affiliate tier 1
    mapping(uint32 => EnumerableSet.AddressSet) private referralLv1;
    // Detail of affiliate tier 2
    mapping(uint32 => EnumerableSet.AddressSet) private referralLv2;
    // Detail of all referrals
    mapping(uint32 => Referral) private referralDetails;

    bytes32 public constant STORE_ROLE = keccak256("STORE_ROLE");

    uint32 public earningRateLv1;
    uint32 public earningRateLv2;

    uint256 public referralPrice;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        earningRateLv1 = 15;
        earningRateLv2 = 3;
        referralPrice = 10;
    }

    /*
        Admin's function BEGIN
    */
    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) 
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(_memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"SHFAffiliate: Incorrect Feed");
    }

    function _memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /*
        @dev This function will set EarningRateLv1 - price of a referral code
    */
    function setEarningRateLv1(uint32 _earningRateLv1)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SHFAffiliate: Caller is not admin");
        require(_earningRateLv1 > 0, "SHFAffiliate: Rate not accepted");
        earningRateLv1 = _earningRateLv1;
    }

    /*
        @dev This function will set EarningRateLv2 - price of a referral code
    */
    function setEarningRateLv2(uint32 _earningRateLv2)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SHFAffiliate: Caller is not admin");
        require(_earningRateLv2 > 0, "SHFAffiliate: Rate not accepted");
        earningRateLv2 = _earningRateLv2;
    }

    /*
        @dev This function will set referralPrice - price of a referral code
    */
    function setReferralPrice(uint256 _price)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SHFAffiliate: Caller is not admin");
        require(_price > 0, "SHFAffiliate: Price not accepted");
        referralPrice = _price;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFAffiliate: Caller is not an admin"
        );
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }
    /*
        Admin's function END
    */

    function _getLatestPrice(uint256 salePrice)
        internal
        view 
        returns (uint)
    {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "SHFAffiliate: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    /*
        We have to convert NFT's price from BUSD to BNB/SHF
    */
    function convertPrice(
        uint256 _amount,
        address _currencyTarget
    )
        public
        view
        returns (uint)
    {
        if(_currencyTarget == address(0)){
            return _getLatestPrice(_amount);
        } else {
            // TODO: process if _currencyTarget = SHF
            uint busd2shfRate = 500 * 10** 9;  // busd/shf = 1/500, rateDecimals is 9
            return busd2shfRate * _amount;
        }
    }

    /*
        User can retrieve fee of referral registration in BNB
    */
    function getReferralPriceInBNB()
        public
        view
        returns(uint256)
    {
        return _getLatestPrice(uint256(referralPrice));
    }

    /*
        User can retrieve fee of referral registration in USD
    */
    function getReferralPriceInUSD()
        public
        view
        returns(uint256)
    {
        return uint256(referralPrice);
    }

    /*
        Referral system
    */

    /*
        Generate an unique code for a user
    */
    function _generateReferralCode(address _user) 
        internal
        view
        returns(uint32)
    {
        require(_user != address(0), "SHFAffiliate: cannot generate referral code for address zero");
        
        uint32 refCode = 0;
        string memory input = "";
        do {
            input = string(abi.encodePacked(input, _user));
            uint hashValue = uint(keccak256(abi.encodePacked(input)));
            uint32 range = 0xffffffff;
            refCode = uint32(hashValue % range);
        } while (refCode != 0 && referralDetails[refCode].user != address(0)); // make sure this referral code has not been issued to any user yet
        
        return uint32(refCode);
    }

    /*
        Create new user's referral information
    */
    function _createNewReferralInformation(address _user)
        internal
        returns(uint32)
    {
        if(referralLists[_user] == 0) {
            // add to list codes
            referralLists[_user] = _generateReferralCode(_user);
            // add detail
            referralDetails[referralLists[_user]].user = _user;
            referralDetails[referralLists[_user]].referrerCode = 0;
            referralDetails[referralLists[_user]].totalAmount = 0;
            referralDetails[referralLists[_user]].totalAmountGenRefCode = 0;
            referralDetails[referralLists[_user]].currentAmountGenRefCode = 0;
            referralDetails[referralLists[_user]].isActive = false;
        }
        return referralLists[_user];
    }

    /*
        User can buy referral code to earning program by deposit money
    */
    function registerReferral()
        external
        payable
        returns(uint32)
    {
        uint referralPriceInBNB = _getLatestPrice(referralPrice);
        // deposit $referralPrice
        require(msg.value >= referralPriceInBNB, "SHFAffiliate: Not enough balance");

        // Generate new referral code if this user is a new user
        if(referralLists[msg.sender] == 0) {
            _createNewReferralInformation(msg.sender);
        }
        // Activate earning program for this referral code
        referralDetails[referralLists[msg.sender]].isActive = true;

        // Distribute commission for referrers
        uint32 refCode = referralLists[msg.sender];
        if(referralDetails[refCode].referrerCode != 0) {
            // referrer level 1 code
            uint32 refLv1 = referralDetails[refCode].referrerCode;
            _addCommisionReferral(refLv1, referralPriceInBNB, earningRateLv1);
            
            if(referralDetails[refLv1].referrerCode != 0) {
                // referrer level 2 code
                uint32 refLv2 = referralDetails[refLv1].referrerCode;
                _addCommisionReferral(refLv2, referralPriceInBNB, earningRateLv2);
            }

            
            
        }
        return referralLists[msg.sender];
    }

    /*
        For special case of "User can buy referral code to earning program by deposit money"
    */
    function registerReferralWithCode(uint32 _referrerCode)
        external
        payable
    {
        uint referralPriceInBNB = _getLatestPrice(referralPrice);
        // deposit $referralPrice
        require(msg.value >= referralPriceInBNB, "SHFAffiliate: Not enough balance");

        // Generate new referral code if this user is a new user
        if(referralLists[msg.sender] == 0) {
            _createNewReferralInformation(msg.sender);
        }
        // Activate earning program for this referral code
        referralDetails[referralLists[msg.sender]].isActive = true;

        uint32 refCode = referralLists[msg.sender];
        // if referrer of user is empty and referrerCode is valid
        if(referralDetails[refCode].referrerCode == 0 && checkReferralCode(_referrerCode) == 0) {
            // add _referrerCode for this user
            referralDetails[refCode].referrerCode = _referrerCode;
            // Distribute commission for referrers
            // referrer level 1 code
            uint32 refLv1 = _referrerCode;
            _addCommisionReferral(refLv1, referralPriceInBNB, earningRateLv1);
            
            if(referralDetails[refLv1].referrerCode != 0) {
                // referrer level 2 code
                uint32 refLv2 = referralDetails[refLv1].referrerCode;
                _addCommisionReferral(refLv2, referralPriceInBNB, earningRateLv2);
            }
        }
    }

    /*
        add commision to totalAmountGenRefCode and currentAmountGenRefCode of user history
    */
    function _addCommisionReferral(uint32 _referrerCode, uint _price, uint128 _rate)
        internal
    {
        referralDetails[_referrerCode].totalAmountGenRefCode += (_price * _rate / 100);
        referralDetails[_referrerCode].currentAmountGenRefCode += (_price * _rate / 100);
        if(_rate == earningRateLv1) {
            referralLv1[_referrerCode].add(msg.sender);
        }
        else {
            referralLv2[_referrerCode].add(msg.sender);
        }
    }

    /*
        Retrieve referral code of user
    */
    function getReferralCode()
        public
        view
        returns(uint32)
    {
        return referralLists[msg.sender];
    }

    /*
        Retrieve referral data of user
    */
    function getReferralData()
        external
        view
        returns(Referral memory)
    {
        require(msg.sender != address(0), "SHFAffiliate: cannot get referral data for address zero");
        require(referralLists[msg.sender] != 0, "SHFAffiliate: Newbie has no referral code");
        Referral memory rs = referralDetails[referralLists[msg.sender]];
        return rs;
    }

    function checkReferralCode(uint32 _code)
        public
        view
        returns(uint)
    {
        if (_code == 0) {
            // "SHFAffiliate: _code cannot equal 0"
            return uint(3);
        }
        else if(referralDetails[_code].user == address(0)) {
            // "SHFAffiliate: referral code incorrect"
            return uint(1);
        }
        else if (referralDetails[_code].isActive == false) {
            // "SHFAffiliate: user not joined the referral program"
            return uint(2);
        }
        else {
            return uint(0);
        }
    }

    /*
        if user had referrer before
    */
    function hasReferrer()
        public
        view
        returns(bool)
    {
        return _hasReferrerTier1(msg.sender);
    }

    /*
        if user had referrer before
    */
    function hasReferrerTier1ForStore(address _user)
        public
        view
        returns(bool)
    {
        return _hasReferrerTier1(_user);
    }

    /*
        if user had referrer lv 1
    */
    function _hasReferrerTier1(address _user)
        internal
        view
        returns(bool)
    {
        return (referralLists[_user] != 0 && referralDetails[referralLists[_user]].referrerCode != 0);
    }

    /*
        if user had referrer lv 1
    */
    function hasReferrerTier2ForStore(address _user)
        public
        view
        returns(bool)
    {
        return (_hasReferrerTier1(_user) && referralDetails[_getReferrerCodeTier1(_user)].referrerCode != 0);
    }

    /*
        check sender has referral code
    */
    function isNewbie()
        public
        view
        returns(bool)
    {
        return referralLists[msg.sender] == 0;
    }

    /*
        User can add his referrer
        @dev user must be newbie (never buy any NFT from store. If he owns NFT from gifts or deposit loan, he's still newbie)
        @dev referrer's code must belong to some other user
        @dev before adding referrer, user will be issued a new referral code for him self.
        @dev check if user own NFT, activate earning program for him.
        @dev add this user to list referral of referrer.
        @param _code: referrer code
    */
    function addReferrer(address _user, uint32 _code)
        external
    {
        require(
            hasRole(STORE_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SHFAffiliate: Caller is not a Store"
        );
        if( referralDetails[_code].user != address(0) && referralDetails[_code].isActive == true) {
            // Generate new referral code if this user is a new user
            if(referralLists[_user] == 0) {
                _createNewReferralInformation(_user);
            }
            
            // prevent self-referral AND referrer not exist
            if(referralLists[_user] != _code && !_hasReferrerTier1(_user)) {
                // Add referral detail for this user
                referralDetails[referralLists[_user]].referrerCode = _code;     // this user has referrer
            
                // // add this user to referrer's list referrals
                // referralLv1[_code].add(_user);
                // referralLv2[referralDetails[_code].referrerCode].add(_user);
            }
        }
    }

    /*
        User can retrieve his referrer's code
    */
    function getReferrerCode()
        external
        view
        returns(uint32)
    {
        return _getReferrerCodeTier1(msg.sender);       
    }

    /*
        Store can retrieve his referrer's code
    */
    function getReferrerCodeTier1ForStore(address _user)
        external
        view
        returns(uint32)
    {
        return _getReferrerCodeTier1(_user);       
    }

    /*
        User can retrieve his referrer's code
    */
    function _getReferrerCodeTier1(address _user)
        internal
        view
        returns(uint32)
    {
        if(_hasReferrerTier1(_user)) {
            return referralDetails[referralLists[_user]].referrerCode;
        } else {
            return 0;
        }        
    }

    /*
        Store can retrieve his referrer's code
    */
    function getReferrerCodeTier2ForStore(address _user)
        external
        view
        returns(uint32)
    {
        if(hasReferrerTier2ForStore(_user)) {
            return referralDetails[_getReferrerCodeTier1(_user)].referrerCode;
        } else {
            return 0;
            
        }        
    }

    /*
        User can claim get amount of money from generate referral link
    */
    function getClaimableBNB()
        external
        view
        returns(uint256)
    {
        return referralDetails[referralLists[msg.sender]].currentAmountGenRefCode;
    }

    /*
        User can claim money from generate referral link
    */
    function userClaimEarning()
        external
    {
        require(referralLists[msg.sender] != 0, "SHFAffiliate: Newbie has no referral code");
        Referral storage refDetail = referralDetails[referralLists[msg.sender]];
        require(refDetail.currentAmountGenRefCode > 0, "SHFAffiliate: User not enough money to claim");
        require(address(this).balance >= refDetail.currentAmountGenRefCode, "SHFAffiliate: Insufficient balance in the account");

        uint256 claimableAmount = refDetail.currentAmountGenRefCode;

        // clean claimable amount
        refDetail.currentAmountGenRefCode = 0;

        payable(msg.sender).transfer(claimableAmount);
    }

    function addBuyCommisionHistory(address _receiver, uint256 _price)
        external
    {
        referralDetails[referralLists[_receiver]].totalAmount += (_price);
    }

    function getEarningRateLv1()
        external
        view
        returns(uint32)
    {
        return earningRateLv1;
    }

    function getEarningRateLv2()
        external
        view
        returns(uint32)
    {
        return earningRateLv2;
    }

    function getAddressOfCode(uint32 _code)
        external
        view
        returns(address)
    {
        return referralDetails[_code].user;
    }

    function countAffiliateTier1()
        external
        view
        returns(uint256)
    {
        return referralLv1[referralLists[msg.sender]].length();
    }

    function countAffiliateTier2()
        external
        view
        returns(uint256)
    {
        return referralLv2[referralLists[msg.sender]].length();
    }

    // for test
    function getAffiliateTier1At(uint _indx)
        external
        view
        returns(address)
    {
        return referralLv1[referralLists[msg.sender]].at(_indx);
    }
    function getAffiliateTier2At(uint _indx)
        external
        view
        returns(address)
    {
        return referralLv2[referralLists[msg.sender]].at(_indx);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Burnable_init_unchained();
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/AggregatorV3Interface.sol";

contract PrivateSale is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    AggregatorV3Interface internal bnbPriceFeed;

    uint private soldAmountToken;
    uint private soldAmountBNB;

    // total number of Token will be sold
    uint private maxPool;

    uint public minAmount;
    uint public maxAmount;

    uint public tokenPrice;

    uint private decimalTokenPrice;

    // 18 months or 24 months
    uint public unlockDuration;

    address public tokenAddress;

    address private marketingWallet;
    address private managerWallet;

    struct Info {
        address user;

        uint32 referrerCode;

        EnumerableSet.AddressSet affLv1;
        EnumerableSet.AddressSet affLv2;
        EnumerableSet.AddressSet affLv3;

        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    // User retrieves information
    struct InfoView {
        address user;

        uint32 referrerCode;

        uint affLv1;
        uint affLv2;
        uint affLv3;

        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    EnumerableMap.AddressToUintMap investorsMap;
    mapping(uint32 => Info) investorDetails;

    uint32 public affiliateRateLv1;
    uint32 public affiliateRateLv2;
    uint32 public affiliateRateLv3;

    uint private countAffTier1;
    uint private countAffTier2;
    uint private countAffTier3;

    uint private startCountdown;

    // Private sale is activate. User only can buy when private sale is active
    bool public isActive;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        soldAmountToken = 0;
        soldAmountBNB = 0;
        maxPool = 650*10**6;

        tokenPrice = 36;    //decimal = 10**4
        decimalTokenPrice = 10**4;

        unlockDuration = 18;

        minAmount = 100;
        maxAmount = 10000;

        affiliateRateLv1 = 7;
        affiliateRateLv2 = 5;
        affiliateRateLv3 = 3;

        countAffTier1 = 0;
        countAffTier2 = 0;
        countAffTier3 = 0;

        startCountdown = 0;
    }

    /*
        Admin's function BEGIN
    */
    function getAllInvestors()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(InfoView [] memory)
    {
        InfoView[] memory investors = new InfoView [](investorsMap.length());

        for(uint i = 0; i<investorsMap.length(); i++) {
            address addTemp;
            (addTemp, ) = investorsMap.at(i);
            investors[i] = _getUserInfo(addTemp);
        }
        
        return investors;
    }

    function setTokenCurrency(address _currency)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        tokenAddress = _currency;
    }
    function setTokenPrice(uint _price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_price >= 1, "PrivateSale: Price too small");
        tokenPrice = _price;
    }
    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(_memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"PrivateSale: Incorrect Feed");
    }

    function _memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /*
       @dev admin can add information of private sale investors
    */
    function adminAddInvestors(address[] calldata _investors, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for(uint i = 0; i<_investors.length; i++) {
            soldAmountToken = soldAmountToken + _amounts[i];
            uint32 code = _createNewAffiliateInformation(_investors[i]);
            investorDetails[code].totalTokenAmount = _amounts[i];
            investorDetails[code].claimedTokenAmount = 0;
            investorDetails[code].boughtAt = block.timestamp;
        }
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        @dev This function will set maximum and minimum USD that user can pay to buy
    */
    function setAmountMoney(uint256 _minPrice, uint256 _maxPrice)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PrivateSale: Caller is not admin");
        require(_minPrice > 0, "PrivateSale: Minimum price not accepted");
        require(_maxPrice >= _minPrice, "PrivateSale: Maximum price not accepted");
        minAmount = _minPrice;
        maxAmount = _maxPrice;
    }

    /*
        Admin can set the maximum Tokens in private sale
        @param: _maxPool - Before call this function, ERC20 of contract must greater or equal _maxPool
    */
    function setMaxPool(uint _maxPool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_maxPool > 0, "PrivateSale: pool amount must greater than 0");
        // require(_maxPool <= IERC20(tokenAddress).balanceOf(address(this)), "PrivateSale: pool amount too large");
        maxPool = _maxPool;
    }

    function setMarketingWallet(address _marketingWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_marketingWallet != address(0), "PrivateSale: Marketing wallet cannot be address 0");
        marketingWallet = _marketingWallet;
    }

    function setManagerWallet(address _managerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_managerWallet != address(0), "PrivateSale: Marketing wallet cannot be address 0");
        managerWallet = _managerWallet;
    }

    /*
        Admin can start and stop private sale
    */
    function activePrivateSale(bool _isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAddress != address(0), "PrivateSale: Token address not specified");
        require(marketingWallet != address(0), "PrivateSale: Marketing wallet not specified");
        require(managerWallet != address(0), "PrivateSale: Manager wallet not specified");
        isActive = _isActive;
    }

    /*
        Admin can set unlock duration (in month)
    */
    function setUnlockDuration(uint _unlockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unlockDuration = _unlockDuration;
    }

    /*
        Admin can change the time to start countdown
    */
    function setCountDownTime(uint _startCountdown)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startCountdown = _startCountdown;
    }

    /*
        Admin can check amount of token sold
    */
    function getAmountToken()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return soldAmountToken;
    }

    /*
        Admin can check amount of BNB sold
    */
    function getAmountBNB()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return soldAmountBNB;
    }

    function countAffiliateTier1()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return countAffTier1;
    }

    function countAffiliateTier2()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return countAffTier2;
    }

    function countAffiliateTier3()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return countAffTier3;
    }

    /*
        Admin's function END
    */

    function getLatestPrice(uint256 salePrice)
        public
        view
        returns (uint)
    {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "PrivateSale: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    /*
        Referral system
    */

    /*
        Generate an unique code for a user
    */
    function _generateReferralCode(address _user)
        internal
        view
        returns(uint32)
    {
        require(_user != address(0), "PrivateSale: cannot generate affiliate code for address zero");

        uint32 refCode = 0;
        string memory input = "";
        do {
            input = string(abi.encodePacked(input, _user));
            uint hashValue = uint(keccak256(abi.encodePacked(input)));
            uint32 range = 0xffffffff;
            refCode = uint32(hashValue % range);
        } while (refCode != 0 && investorDetails[refCode].user != address(0)); // make sure this referral code has not been issued to any user yet

        return uint32(refCode);
    }

    /*
        Create new user's referral information
    */
    function _createNewAffiliateInformation(address _user)
        internal
        returns(uint32)
    {
        uint32 code = _generateReferralCode(_user);
        investorsMap.set(_user, code);
        // add detail
        investorDetails[code].user = _user;
        investorDetails[code].referrerCode = 0;
        investorDetails[code].boughtAt = 0;

        return uint32(investorsMap.get(_user));
    }

    /*
        code validity
    */
    function isValidCode(uint32 _code)
        public
        view
        returns(bool)
    {
        if(_code != 0 && investorDetails[_code].user == address(0)) {
            // "PrivateSale: affiliate code incorrect"
            return false;
        }
        else {
            return true;
        }
    }

    function _distributeCommision(uint32 _code, uint _value)
        internal
    {
        // Affilivate program
        // level 1
        uint commisionAmount = 0;
        if(_code != 0) {
            commisionAmount = commisionAmount + _payCommisionAffiliate(_code, _value, 1);

            // level 2
            uint32 refCodeLv2 = investorDetails[_code].referrerCode;
            if(refCodeLv2 != 0) {
                commisionAmount = commisionAmount + _payCommisionAffiliate(refCodeLv2, _value, 2);

                // level 3
                uint32 refCodeLv3 = investorDetails[refCodeLv2].referrerCode;
                if(refCodeLv3 != 0) {
                    commisionAmount = commisionAmount + _payCommisionAffiliate(refCodeLv3, _value, 3);
                }
            }
        }

        uint theRestAmount = _value - commisionAmount;
        // address private marketingWallet - 11.76%
        uint valueForMarketing = theRestAmount * 1176 / 10000;
        payable(marketingWallet).transfer(valueForMarketing);
        // address private managerWallet;
        // uint valueForManager = _value - commisionAmount - valueForMarketing;
        // payable(managerWallet).transfer(valueForManager);
    }

    /*
        pay commision to referrer
    */
    function _payCommisionAffiliate(uint32 _referrerCode, uint _price, uint128 _affLv)
        internal
        returns(uint)
    {
        uint rate = affiliateRateLv1;
        if(_affLv == 1) {
            investorDetails[_referrerCode].affLv1.add(msg.sender);
            countAffTier1 = countAffTier1 + 1;
        }
        else if (_affLv == 2) {
            rate = affiliateRateLv2;
            investorDetails[_referrerCode].affLv2.add(msg.sender);
            countAffTier2 = countAffTier2 + 1;
        }
        else {
            rate = affiliateRateLv3;
            investorDetails[_referrerCode].affLv3.add(msg.sender);
            countAffTier3 = countAffTier3 + 1;
        }
        payable(investorDetails[_referrerCode].user).transfer(_price * rate / 100);

        return _price * rate / 100;
    }

    function _canBuy(address _user)
        internal
        view
        returns(bool)
    {
        return !investorsMap.contains(_user);
    }

    /*
        we can get amount of token corresponding with amount of BNB
        @param - _amount: amount of BNB
    */
    function getTokenAmountToBuy(uint _amount)
        public
        view
        returns(uint)
    {
        uint tokenAmountOfUser = _amount * decimalTokenPrice / getLatestPrice(tokenPrice);
        return tokenAmountOfUser * (10 ** 9);
    }
	
	receive () external payable {}

    function buy(uint32 _code)
        external
        payable
        returns(uint32)
    {
        require(isActive, "PrivateSale: Not in a private sale");
        require(isValidCode(_code), "PrivateSale: Invalid code");
        require(_canBuy(msg.sender), "PrivateSale: A wallet can buy 1 time only");

        uint tokenAmountOfUser = getTokenAmountToBuy(msg.value);
        // require(soldAmountToken + tokenAmountOfUser <= maxPool, "PrivateSale: The purchase limit has been reached");

        soldAmountToken = soldAmountToken + tokenAmountOfUser;
        soldAmountBNB = soldAmountBNB + msg.value;

        // gen a code for new user
        uint32 code = _createNewAffiliateInformation(msg.sender);
        investorDetails[code].totalTokenAmount = tokenAmountOfUser;
        investorDetails[code].claimedTokenAmount = 0;
        investorDetails[code].boughtAt = block.timestamp;

        // add referrer
        if(_code != 0) {
            investorDetails[uint32(investorsMap.get(msg.sender))].referrerCode = _code;
        }

        uint minAmountInBNB = getLatestPrice(minAmount);
        uint maxAmountInBNB = getLatestPrice(maxAmount);

        require(msg.value >= minAmountInBNB && msg.value <= maxAmountInBNB, "PrivateSale: BNB amount invalid");

        _distributeCommision(_code, msg.value);

        return uint32(investorsMap.get(msg.sender));
    }

    /*
        Admin can retrieve information of a user
    */
    function _getUserInfo(address _user)
        internal
        view
        returns(InfoView memory)
    {
        InfoView memory rs;

        uint32 code = uint32(investorsMap.get(_user));
        rs.user = investorDetails[code].user;

        rs.referrerCode = investorDetails[code].referrerCode;

        rs.affLv1 = investorDetails[code].affLv1.length();
        rs.affLv2 = investorDetails[code].affLv2.length();
        rs.affLv3 = investorDetails[code].affLv3.length();

        rs.totalTokenAmount = investorDetails[code].totalTokenAmount;
        rs.claimedTokenAmount = investorDetails[code].claimedTokenAmount;
        rs.boughtAt = investorDetails[code].boughtAt;

        return rs;
    }

    /*
        User can retrieve his information
    */
    function getInfo()
        external
        view
        returns(InfoView memory)
    {
        return _getUserInfo(msg.sender);
    }

    /*
        Retrieve affiliate code of user
    */
    function getAffiliateCode()
        external
        view
        returns(uint32)
    {
        return uint32(investorsMap.get(msg.sender));
    }

    function getClaimable()
        public
        view
        returns(uint)
    {
        uint32 code = uint32(investorsMap.get(msg.sender));
        uint timeLock = startCountdown + 7 days;
        if (block.timestamp <= timeLock) {
            return 0;
        }
        uint daysDiff = (block.timestamp - timeLock) / 1 days;

        uint unlockDays = 30 * unlockDuration;

        uint unlockedToken = (investorDetails[code].totalTokenAmount < investorDetails[code].totalTokenAmount * daysDiff / unlockDays) ?
                              investorDetails[code].totalTokenAmount : investorDetails[code].totalTokenAmount * daysDiff / unlockDays;
        uint claimableToken = unlockedToken - investorDetails[code].claimedTokenAmount;

        return claimableToken;
    }

    function userClaim()
        external
    {
        uint32 code = uint32(investorsMap.get(msg.sender));
        uint claimableToken = getClaimable();
        investorDetails[code].claimedTokenAmount += claimableToken;
        IERC20(tokenAddress).transfer(msg.sender, claimableToken);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PrivateSaleETH is AccessControlUpgradeable, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    uint private soldAmountToken;

    // 18 months or 24 months
    uint public unlockDuration;

    address public tokenAddress;

    struct Info {
        uint code;
        address user;
        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    address[] private investorsMap;
    mapping(address => Info) investorDetails;

    uint private startCountdown;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        soldAmountToken = 0;

        unlockDuration = 18;

        startCountdown = 0;
    }

    /*
        Admin's function BEGIN
    */
    function getAllInvestors()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(Info [] memory)
    {
        Info[] memory investors = new Info [](investorsMap.length);

        for(uint i = 0; i<investorsMap.length; i++) {
            investors[i] = _getUserInfo(investorsMap[i]);
        }
        
        return investors;
    }

    function setTokenCurrency(address _currency)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        tokenAddress = _currency;
    }

    /*
       @dev admin can add information of private sale investors
    */
    function adminAddInvestors(address[] calldata _investors, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for(uint i = 0; i<_investors.length; i++) {
            soldAmountToken = soldAmountToken + _amounts[i];

            address user = _investors[i];
            uint code = investorsMap.length;
            investorsMap.push(user);

            investorDetails[user].code = code;
            investorDetails[user].user = user;
            investorDetails[user].totalTokenAmount = _amounts[i];
            investorDetails[user].claimedTokenAmount = 0;
            investorDetails[user].boughtAt = block.timestamp;
        }
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PrivateSale: Caller is not an admin"
        );
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        Admin can set unlock duration (in month)
    */
    function setUnlockDuration(uint _unlockDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unlockDuration = _unlockDuration;
    }

    /*
        Admin can change the time to start countdown
    */
    function setCountDownTime(uint _startCountdown)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startCountdown = _startCountdown;
    }

    /*
        Admin can check amount of token sold
    */
    function getAmountToken()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(uint)
    {
        return soldAmountToken;
    }

    /*
        Admin can retrieve information of a user
    */
    function _getUserInfo(address _user)
        internal
        view
        returns(Info memory)
    {
        Info memory rs;

        rs.code = investorDetails[_user].code;
        rs.user = investorDetails[_user].user;
        rs.totalTokenAmount = investorDetails[_user].totalTokenAmount;
        rs.claimedTokenAmount = investorDetails[_user].claimedTokenAmount;
        rs.boughtAt = investorDetails[_user].boughtAt;

        return rs;
    }

    /*
        User can retrieve his information
    */
    function getInfo()
        external
        view
        returns(Info memory)
    {
        return _getUserInfo(msg.sender);
    }

    function getClaimable()
        public
        view
        returns(uint)
    {
        address user = msg.sender;
        uint timeLock = startCountdown + 7 days;
        if (block.timestamp <= timeLock) {
            return 0;
        }
        uint daysDiff = (block.timestamp - timeLock) / 1 days;

        uint unlockDays = 30 * unlockDuration;

        uint unlockedToken = (investorDetails[user].totalTokenAmount < investorDetails[user].totalTokenAmount * daysDiff / unlockDays) ?
                              investorDetails[user].totalTokenAmount : investorDetails[user].totalTokenAmount * daysDiff / unlockDays;
        uint claimableToken = unlockedToken - investorDetails[user].claimedTokenAmount;

        return claimableToken;
    }

    function userClaim()
        external
    {
        address user = msg.sender;
        uint claimableToken = getClaimable();
        investorDetails[user].claimedTokenAmount += claimableToken;
        IERC20(tokenAddress).transfer(msg.sender, claimableToken);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/AggregatorV3Interface.sol";

contract PreIdo is AccessControlUpgradeable, PausableUpgradeable {
    AggregatorV3Interface internal bnbPriceFeed;

    address public tokenAddress;

    struct Info {
        address user;
        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    mapping(address => uint) investorsMap;
    Info[] investorDetails;

    struct IDOInfor {
        address tokenAddress;
        uint soldAmountToken;
        uint soldAmountBNB;
        uint minAmount;
        uint tokenPrice;
        uint decimalTokenPrice;
        uint decimalToken;
        uint ideTime;
        uint firstUnlock;
        uint secondUnlock;
        uint rateIDE;
        uint rateFirstTime;
        uint rateSecondTime;
        bool isActive;
    }

    uint private soldAmountToken;
    uint private soldAmountBNB;

    uint public minAmount;

    uint public tokenPrice;
    uint private decimalTokenPrice;

    uint private decimalToken;

    uint public ideTime;
    uint public firstUnlock;
    uint public secondUnlock;

    uint public rateIDE;
    uint public rateFirstTime;
    uint public rateSecondTime;

    bool public isActive;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        soldAmountToken = 0;
        soldAmountBNB = 0;

        tokenPrice = 54;    //decimal = 10**4
        decimalTokenPrice = 10**4;
        decimalToken = 10**9;

        ideTime = 0;
        firstUnlock = 60;
        secondUnlock = 90;

        rateIDE = 30;
        rateFirstTime = 35;
        rateSecondTime = 35;

        minAmount = 100;
    }

    /*
        Admin's function BEGIN
    */
    function getPreIDOInfor()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(IDOInfor memory)
    {
        IDOInfor memory rs;
        rs.tokenAddress = tokenAddress;
        rs.soldAmountToken = soldAmountToken;
        rs.soldAmountBNB = soldAmountBNB;
        rs.minAmount = minAmount;
        rs.tokenPrice = tokenPrice;
        rs.decimalTokenPrice = decimalTokenPrice;
        rs.decimalToken = decimalToken;
        rs.ideTime = ideTime;
        rs.firstUnlock = firstUnlock;
        rs.secondUnlock = secondUnlock;
        rs.rateIDE = rateIDE;
        rs.rateFirstTime = rateFirstTime;
        rs.rateSecondTime = rateSecondTime;
        rs.isActive = isActive;
        return rs;
    }

    function getAllInvestors()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(Info [] memory)
    {
        Info[] memory investors = new Info [](investorDetails.length);

        for(uint i = 0; i<investorDetails.length; i++) {
            investors[i] = investorDetails[i];
        }
        
        return investors;
    }

    function setTokenAddress(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _currency;
    }

    function setTokenPrice(uint _price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_price >= 1, "PreIdo: Price too small");
        tokenPrice = _price;
    }
    
    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(_memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"PreIdo: Incorrect Feed");
    }

    function _memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /*
       @dev admin can add information of private sale investors
    */
    function adminAddInvestors(address[] calldata _investors, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for(uint i = 0; i<_investors.length; i++) {
            soldAmountToken = soldAmountToken + _amounts[i];

            investorsMap[_investors[i]] = investorDetails.length;

            investorDetails.push(Info(_investors[i], _amounts[i], 0, block.timestamp));
        }
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        @dev This function will set minimum USD that user can pay to buy
    */
    function setMinimumMoney(uint256 _minPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_minPrice > 0, "PreIdo: Minimum price not accepted");
        minAmount = _minPrice;
    }

    /*
        Admin can start and stop private sale
    */
    function activePreIDO(bool _isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAddress != address(0), "PreIdo: Token address not specified");
        isActive = _isActive;
    }

    /*
        Admin can set timestamp of IDE and claim rate
    */
    function setIdeTime(uint _ideTime, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ideTime = _ideTime;
        rateIDE = _rate;
    }

    /*
        Admin can set the period of the first unlock and unlock rate
    */
    function setFirstUnlockTime(uint _firstUnlock, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        firstUnlock = _firstUnlock;
        rateFirstTime = _rate;
    }

    /*
        Admin can set the period of the second unlock and unlock rate
    */
    function setSecondUnlockTime(uint _secondUnlock, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        secondUnlock = _secondUnlock;
        rateSecondTime = _rate;
    }

    /*
        Admin's function END
    */

    function getLatestPrice(uint256 salePrice)
        public
        view
        returns (uint)
    {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "PreIdo: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }

    // user bought pre IDO or not
    function isBought(address _user)
        public
        view
        returns(bool)
    {
        return (investorsMap[_user] != 0) || 
               (investorDetails.length > 0 && investorDetails[investorsMap[_user]].user == _user);
    }

    /*
        we can get amount of token corresponding with amount of BNB
        @param - _amount: amount of BNB
    */
    function getTokenAmountToBuy(uint _amount)
        public
        view
        returns(uint)
    {
        uint tokenAmountOfUser = _amount * decimalTokenPrice / getLatestPrice(tokenPrice);
        return tokenAmountOfUser * decimalToken;
    }
	
    function buy()
        external
        payable
    {
        require(isActive, "PreIdo: Not in a private sale");
        require(!isBought(msg.sender), "PreIdo: A wallet can buy 1 time only");

        uint tokenAmountOfUser = getTokenAmountToBuy(msg.value);

        soldAmountToken = soldAmountToken + tokenAmountOfUser;
        soldAmountBNB = soldAmountBNB + msg.value;

        investorsMap[msg.sender] = investorDetails.length;

        investorDetails.push(Info(msg.sender, tokenAmountOfUser, 0, block.timestamp));

        uint minAmountInBNB = getLatestPrice(minAmount);

        require(msg.value >= minAmountInBNB, "PreIdo: BNB amount invalid");
    }

    /*
        User can retrieve his information
    */
    function getInfo()
        external
        view
        returns(Info memory)
    {
        Info memory rs;

        if(isBought(msg.sender)) {
            uint code = investorsMap[msg.sender];

            rs.user = investorDetails[code].user;
            rs.totalTokenAmount = investorDetails[code].totalTokenAmount;
            rs.claimedTokenAmount = investorDetails[code].claimedTokenAmount;
            rs.boughtAt = investorDetails[code].boughtAt;
        }

        return rs;
    }

    function getClaimable()
        public
        view
        returns(uint)
    {
        uint claimableToken = 0;

        if(isBought(msg.sender)) {
            uint unlockedToken = 0;
            if (block.timestamp >= (ideTime + (secondUnlock * 1 days))) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount;

            }else if(block.timestamp >= (ideTime + (firstUnlock * 1 days))) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount * (rateIDE + rateFirstTime) / 100;

            } else if(block.timestamp >= ideTime) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount * rateIDE / 100;

            }
            claimableToken = unlockedToken - investorDetails[investorsMap[msg.sender]].claimedTokenAmount;
        }

        return claimableToken;
    }

    function userClaim()
        external
    {
        require(isBought(msg.sender), "PreIdo: User must buy pre IDO");

        uint code = investorsMap[msg.sender];
        uint claimableToken = getClaimable();
        investorDetails[code].claimedTokenAmount += claimableToken;
        IERC20(tokenAddress).transfer(msg.sender, claimableToken);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/AggregatorV3Interface.sol";

contract PreIdoETH is AccessControlUpgradeable, PausableUpgradeable {
    AggregatorV3Interface internal ethPriceFeed;

    address public tokenAddress;

    struct Info {
        address user;
        uint totalTokenAmount;
        uint claimedTokenAmount;
        uint boughtAt;
    }

    mapping(address => uint) investorsMap;
    Info[] investorDetails;

    struct IDOInfor {
        uint soldAmountToken;
        uint soldAmountETH;
    }

    uint private soldAmountToken;
    uint private soldAmountETH;

    uint public minAmount;

    uint public tokenPrice;
    uint public decimalTokenPrice;

    uint private decimalToken;

    uint public tgeTime;
    uint public firstUnlock;
    uint public secondUnlock;

    uint public rateTGE;
    uint public rateFirstTime;
    uint public rateSecondTime;

    bool public isActive;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

        soldAmountToken = 0;
        soldAmountETH = 0;

        tokenPrice = 36;    //decimal = 10**4
        decimalTokenPrice = 10**4;
        decimalToken = 10**9;

        tgeTime = 0;
        firstUnlock = 29;
        secondUnlock = 59;

        rateTGE = 30;
        rateFirstTime = 35;
        rateSecondTime = 35;

        minAmount = 100;
    }

    /*
        Admin's function BEGIN
    */
    function getPreIDOInfor()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(IDOInfor memory)
    {
        IDOInfor memory rs;
        rs.soldAmountToken = soldAmountToken;
        rs.soldAmountETH = soldAmountETH;

        return rs;
    }

    function getAllInvestors()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(Info [] memory)
    {
        Info[] memory investors = new Info [](investorDetails.length);

        for(uint i = 0; i<investorDetails.length; i++) {
            investors[i] = investorDetails[i];
        }
        
        return investors;
    }

    function setTokenAddress(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _currency;
    }

    function setTokenPrice(uint _price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_price >= 1, "PreIdoETH: Price too small");
        tokenPrice = _price;
    }
    
    // priceFeed should be something like USDT/ETH or DAI/ETH
    function setETHPriceFeed(address _priceFeed, string calldata _description)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ethPriceFeed = AggregatorV3Interface(_priceFeed);
        require(_memcmp(bytes(ethPriceFeed.description()), bytes(_description)),"PreIdoETH: Incorrect Feed");
    }

    function _memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns(bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /*
       @dev admin can add information of private sale investors
    */
    function adminAddInvestors(address[] calldata _investors, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for(uint i = 0; i<_investors.length; i++) {
            soldAmountToken = soldAmountToken + _amounts[i];

            investorsMap[_investors[i]] = investorDetails.length;

            investorDetails.push(Info(_investors[i], _amounts[i], 0, block.timestamp));
        }
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (_currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        @dev This function will set minimum USD that user can pay to buy
    */
    function setMinimumMoney(uint256 _minPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_minPrice > 0, "PreIdoETH: Minimum price not accepted");
        minAmount = _minPrice;
    }

    /*
        Admin can start and stop private sale
    */
    function activePreIDO(bool _isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAddress != address(0), "PreIdoETH: Token address not specified");
        isActive = _isActive;
    }

    /*
        Admin can set timestamp of IDE and claim rate
    */
    function setTgeTime(uint _tgeTime, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tgeTime = _tgeTime;
        rateTGE = _rate;
    }

    /*
        Admin can set the period of the first unlock and unlock rate
    */
    function setFirstUnlockTime(uint _firstUnlock, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        firstUnlock = _firstUnlock;
        rateFirstTime = _rate;
    }

    /*
        Admin can set the period of the second unlock and unlock rate
    */
    function setSecondUnlockTime(uint _secondUnlock, uint _rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        secondUnlock = _secondUnlock;
        rateSecondTime = _rate;
    }

    /*
        Admin's function END
    */

    function getLatestPrice(uint256 salePrice)
        public
        view
        returns (uint)
    {
        (
            , int price, , ,
        ) = ethPriceFeed.latestRoundData();
        require(price > 0, "PreIdoETH: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as ETH, we don't need to do anything
    }

    // user bought pre IDO or not
    function isBought(address _user)
        public
        view
        returns(bool)
    {
        return (investorsMap[_user] != 0) || 
               (investorDetails.length > 0 && investorDetails[investorsMap[_user]].user == _user);
    }

    /*
        we can get amount of token corresponding with amount of ETH
        @param - _amount: amount of ETH
    */
    function getTokenAmountToBuy(uint _amount)
        public
        view
        returns(uint)
    {
        uint tokenAmountOfUser = _amount * decimalTokenPrice / getLatestPrice(tokenPrice);
        return tokenAmountOfUser * decimalToken;
    }
	
    function buy()
        external
        payable
    {
        require(isActive, "PreIdoETH: Not in a private sale");
        require(!isBought(msg.sender), "PreIdoETH: A wallet can buy 1 time only");

        uint tokenAmountOfUser = getTokenAmountToBuy(msg.value);

        soldAmountToken = soldAmountToken + tokenAmountOfUser;
        soldAmountETH = soldAmountETH + msg.value;

        investorsMap[msg.sender] = investorDetails.length;

        investorDetails.push(Info(msg.sender, tokenAmountOfUser, 0, block.timestamp));

        uint minAmountInETH = getLatestPrice(minAmount);

        require(msg.value >= minAmountInETH, "PreIdoETH: ETH amount invalid");
    }

    /*
        User can retrieve his information
    */
    function getInfo()
        external
        view
        returns(Info memory)
    {
        Info memory rs;

        if(isBought(msg.sender)) {
            uint code = investorsMap[msg.sender];

            rs.user = investorDetails[code].user;
            rs.totalTokenAmount = investorDetails[code].totalTokenAmount;
            rs.claimedTokenAmount = investorDetails[code].claimedTokenAmount;
            rs.boughtAt = investorDetails[code].boughtAt;
        }

        return rs;
    }

    function getClaimable()
        public
        view
        returns(uint)
    {
        uint claimableToken = 0;

        if(isBought(msg.sender)) {
            uint unlockedToken = 0;
            if (block.timestamp >= (tgeTime + (secondUnlock * 1 days))) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount;

            }else if(block.timestamp >= (tgeTime + (firstUnlock * 1 days))) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount * (rateTGE + rateFirstTime) / 100;

            } else if(block.timestamp >= tgeTime) {

                unlockedToken = investorDetails[investorsMap[msg.sender]].totalTokenAmount * rateTGE / 100;

            }
            claimableToken = unlockedToken - investorDetails[investorsMap[msg.sender]].claimedTokenAmount;
        }

        return claimableToken;
    }

    function userClaim()
        external
    {
        require(isBought(msg.sender), "PreIdoETH: User must buy pre IDO");

        uint code = investorsMap[msg.sender];
        uint claimableToken = getClaimable();
        investorDetails[code].claimedTokenAmount += claimableToken;
        IERC20(tokenAddress).transfer(msg.sender, claimableToken);
    }
}