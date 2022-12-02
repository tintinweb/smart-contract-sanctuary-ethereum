/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

pragma solidity 0.8.17;

abstract contract GatekeeperOneContract
{
    function enter(bytes8 _gateKey) public virtual returns (bool);
}

contract GatekeeperOneHelper
{
    bytes8 public key = 0x100000000000A347;
    GatekeeperOneContract gatekeeper = GatekeeperOneContract(0xC32c04A03b3c35d6c96C5823318A25C8ACD846F6);

    function enter() public
    {
        for (uint i = 0; i < 8191; i++)
        {
            try gatekeeper.enter{gas: 100000 + i}(key)
            {
                return;
            }
            catch
            {

            }
        }
    }
}