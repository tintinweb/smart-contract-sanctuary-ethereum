pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract GRInsurance is ERC20, Ownable {

    IERC20 private grom;

    constructor(
        string memory name,
        string memory symbol,
        IERC20 gromContract
    ) ERC20(name, symbol) {
        grom = gromContract;
    }

    struct Insurance {
        uint id;
        string name;
    }

    Insurance[] public insurances;

    struct InsuranceUser {
        uint id;
        string name;
    }

    mapping(address => InsuranceUser[]) public insuranceUsers;

    function addInsurance(uint _id, string memory _name) external onlyOwner {
        Insurance memory new_insurance = Insurance(_id, _name);
        insurances.push(new_insurance);
    }

    function getInsurance(uint _index) public view returns (uint id, string memory name) {
        Insurance storage insurance = insurances[_index];
        return (insurance.id, insurance.name);
    }

    function getInsuranceById(uint _id) public view returns (uint id, string memory name) {
        for (uint i = 0; i <= insurances.length; i++) {
            Insurance storage insurance = insurances[i];
            if (_id == insurance.id) {
                return (insurance.id, insurance.name);
            }
        }
        return (0, '');
    }

    function addInsuranceUser(uint _id, string memory _name) public {
        InsuranceUser memory new_insurance = InsuranceUser(_id, _name);
        insuranceUsers[msg.sender].push(new_insurance);
    }

    function getInsuranceUser(address _address, uint _index) public view returns (uint id, string memory name) {
        InsuranceUser storage insuranceUser = insuranceUsers[_address][_index];
        return (insuranceUser.id, insuranceUser.name);
    }

    function getInsuranceUserById(address _address, uint _id) public view returns (uint id, string memory name) {
        for (uint i = 0; i <= insuranceUsers[_address].length; i++) {
            InsuranceUser storage insuranceUser = insuranceUsers[_address][i];
            if (_id == insuranceUser.id) {
                return (insuranceUser.id, insuranceUser.name);
            }
        }
        return (0, '');
    }

    function byGr(uint256 _amount) public {
        uint256 allowance = grom.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");

        (bool sent) = grom.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to send GROM");
    }

    function withdrawGr() external onlyOwner {
        uint256 balance = grom.balanceOf(address(this));
        require(balance > 0, "Amount sent is not correct");

        grom.transfer(owner(), balance);
    }
}