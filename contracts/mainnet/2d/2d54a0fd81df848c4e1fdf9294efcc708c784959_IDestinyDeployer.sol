/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT
// File: contracts/ICreate2Factory.sol
pragma solidity ^0.8.10;
/// @notice Integrated, used to deploy contracts using Create2, only the owner can call.
contract IDestinyDeployer{
    event Deployed(address addr, bytes32 salt);

    modifier onlyDESTINY_EXCUTORS(){
        require(msg.sender == KIYOMIYA || msg.sender == SOFTCLAY || msg.sender == XIZI || msg.sender == SUYUQING || msg.sender == DUYUXUAN || msg.sender == CICADA ||msg.sender == JIANYUE || msg.sender == UMO || msg.sender == ULI || msg.sender == HARUKA,"NOT DESTINY EXCUTORS.");
        _;    
    }
    address constant internal KIYOMIYA = 0x00001C1D6ab92F943eD4A31dA8F447Fd96589960;
    address constant internal SOFTCLAY = 0x11119C3A27d5D7E13cb52053aF58b2DBddcFE051;
    address constant internal XIZI = 0x22222eC77C520Bdb7D6A2450C3dB3c5c138C4372;
    address constant internal SUYUQING = 0x33339BE5D3C5C7ae99c1532df8a09F859770B3E3;
    address constant internal DUYUXUAN = 0x4444023B8E794eCD3a21335fcA22675739bD7914;
    address constant internal CICADA = 0x555599F812DC2Cf428d67339221e2B066e7fCAe5;
    address constant internal JIANYUE = 0x66660Bd655e77b2d8b0Ad9F87b4c48D7f284E9b6;
    address constant internal UMO = 0x77777DCaEfeaC067f21162cd2F48E5b5dB0A2B97;
    address constant internal ULI = 0x888853CFdAB45eB0608Acc157C6295E8eFD617a8;
    address constant internal HARUKA = 0x99995D080A1bfa91d065dD14C567089D103BfBB9;
    /// @notice Calculate create2 deploy contract address.
    function getAddress(bytes memory bytecode, string memory salt)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), keccak256(abi.encodePacked(salt)), keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }
    
    /**
    * @custom:title Deploy the contract
    * @notice Check the event log Deployed which contains the address of the deployed Contract.
    * The address in the log should equal the address computed from above.
    */
    function deploy(bytes memory bytecode, bytes32 salt) public onlyDESTINY_EXCUTORS returns(address){
        address addr;
        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                salt // Salt from function arguments
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
        return addr;
    }
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>The above verification passed.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/