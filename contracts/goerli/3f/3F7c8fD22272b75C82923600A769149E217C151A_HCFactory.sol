// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./HoldingCompany.sol";

contract HCFactory {
    mapping(string => address) private companies;
    event HCCreated(address hcaddr, string name);

    function createHC(string calldata _name) external returns(address){
        HoldingCompany company = new HoldingCompany(_name);
        address addr = address(company);
        emit HCCreated(addr, _name);
        companies[_name] = addr;
        return addr;
    }
    function getHCAddr(string calldata _name) external view returns(address){
        return companies[_name];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HoldingCompany {
    string name;
    event CommitOccurred(address to, uint256 amount);
    event TransferOccurred(address to, uint256 amount);
    
    mapping(address => uint256) commitments;

    constructor(string memory _name) {
        name = _name;
    }
    
    // User commits a certain amount of holding company's funds to a private equity
    function commit(address to, uint256 amount) public returns (uint256) {
        uint256 curr = commitments[to];
        uint256 new_amount = curr + amount;
        commitments[to] = new_amount;
        emit CommitOccurred(to, new_amount);
        return new_amount;
    }

    // User reduces the commitment of holding company's funds to private equity by certain amount
    function commitReduction(address to, uint256 amount) public returns (uint256) {
        uint256 curr = commitments[to];
        uint256 new_amount;
        if (curr - amount < 0) {
            new_amount = 0;
        } else {
            new_amount = curr - amount;
        }
        commitments[to] = new_amount;
        emit CommitOccurred(to, new_amount);
        return new_amount;
    }

    // User contributes amount of holding company's funds to private equity
    function contribute(address to, uint256 amount, uint256 txId) public returns (uint256) {
        commitments[to] = 0;
        (bool success, bytes memory result) = to.call{value: amount, gas: 1000000}(abi.encodeWithSignature("contribute(uint,uint)", amount, txId));
        if (success) {
            emit TransferOccurred(to, amount);
            return amount;
        }
        return 0;
    }
}