/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.2;

interface IERC20 {
    function transfer(address payable recipient, uint256 amount) external returns (bool);
}

interface Ichild{
    function takeToken(
        address token,
        uint amount,
        address payable receiver)
        external;
    
    function takeMain(
        uint amount,
        address payable receiver)
        external;
}

contract Mother{
    address private owner;
    address private constant mother = 0xf554b22a01D5F250510c0B5E68a002e131763cf2;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (owner == msg.sender);
        _; 
    }
    
    function create_child_with_token(uint salt, address token, uint amount, address payable recv)
        onlyOwner
        external
        returns(address addr) {
        bytes memory bytecode = getBytecode();
        assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        Ichild(addr).takeToken(token, amount, recv);
    }

    function create_child_with_main(uint salt, uint amount, address payable recv)
        onlyOwner
        external
        returns(address addr) {
        bytes memory bytecode = getBytecode();
        assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        Ichild(addr).takeMain(amount, recv);
    }

    function getBytecode()
        public
        pure
        returns (bytes memory) {
        return abi.encodePacked(type(Child).creationCode);
    }

    function getAddress(uint salt)
        external
        view
        returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff),
            address(this),
            salt,
            keccak256(getBytecode()))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    function takeMain(
        uint256 amount,
        address payable receiver) 
        external {
            require(msg.sender == mother);
            receiver.call{value:amount}("");
    }

    function takeToken(
        address token,
        uint256 amount,
        address payable receiver) 
        external {
            require(msg.sender == mother);
            IERC20(token).transfer(receiver, amount);
    }

    function withdraw_main(address _child, uint256 amount, address payable receiver) external onlyOwner{
        Ichild(_child).takeMain(amount, receiver);  
    }
    
    function withdraw_token(address _child, address _token, uint256 amount, address payable receiver) external onlyOwner{
        Ichild(_child).takeToken(_token, amount, receiver);  
    }

    fallback() external{
        revert();
    }
}

contract Child {    
    address private constant mother = 0xf554b22a01D5F250510c0B5E68a002e131763cf2;
    fallback() external payable{
        assembly{   
            if iszero(calldatasize()){
                return(0,0)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(
                gas(),
                mother,
                0,
                calldatasize(),
                0x40,
                0x20)
        }
    }
}