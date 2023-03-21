// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error INSURANCE__NotEnoughETHEntered();


contract Insurance {
    struct Info {
        string name;
        string gender;
        uint256 age;
        uint256 phoneNumber;
        uint256 policyId;
        uint256 premium;
    }

    Info info;

    mapping(address => Info) public checkUser;
    mapping(uint256 => string[]) public policyIdToCoverings;
    mapping(string => uint256) public coveringToPremium; // claim will be 5 times premium.
    // mapping (uint256 => uint256) public policyIdToClaim;

    event POLICY_BOUGHT(uint256 indexed id);

    uint256 fixedFee;
    uint256 id = 0;
    uint256 infoId = 0;
    // string h = "Hospi";

    constructor(
        uint256 _fee,
        uint256 _hpremium,
        uint256 _spremium,
        uint256 _ppremium,
        uint256 _epremium,
        uint256 _pdpremium
    ) {
        fixedFee = _fee;
        coveringToPremium["h"] = _hpremium;
        coveringToPremium["s"] = _spremium;
        coveringToPremium["p"] = _ppremium;
        coveringToPremium["e"] = _epremium;
        coveringToPremium["pd"] = _pdpremium;
    }

    function setInfo(
        string memory _name,
        string memory _gender,
        uint256 _age,
        uint256 _phoneNumber
    ) public {
        require(checkUser[msg.sender].age == 0, "Info already exists");
        info = Info(_name, _gender, _age, _phoneNumber, 0, 0);
        checkUser[msg.sender] = info;
    }

    function buyPolicy(uint256 _premium) external payable {
        uint256 price = fixedFee + _premium;
        require(
            checkUser[msg.sender].policyId == 0,
            "You already have a policy"
        );
        if (msg.value < price) {
            revert INSURANCE__NotEnoughETHEntered();
        }
        id++;
        emit POLICY_BOUGHT(id);
        checkUser[msg.sender].policyId = id;
        checkUser[msg.sender].premium = _premium;
    }

    function payPremium(uint256 _premium) external payable {
        require(
            checkUser[msg.sender].policyId != 0,
            "You do not have a policy"
        );
        if (msg.value < _premium) {
            revert INSURANCE__NotEnoughETHEntered();
        }
    }

    function claim() external {
        address payable claimer = payable(msg.sender);
        uint256 _amount = 5 * (checkUser[msg.sender].premium);
        (bool success, ) = claimer.call{value: _amount}("");
    }

    function getPolicyId() public view returns (uint256) {
        return checkUser[msg.sender].policyId;
    }
}