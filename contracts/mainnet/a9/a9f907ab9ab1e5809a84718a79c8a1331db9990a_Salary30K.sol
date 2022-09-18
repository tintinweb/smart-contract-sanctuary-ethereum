// SPDX-License-Identifier: MIT

contract Salary30K {

    receive() external payable {

    }

    function withdraw() external {
        uint balance = address(this).balance;
        payable(0xFeE836516a3Fc5f053F35964a2Bed9af65Da8159).transfer(balance * 5 / 100);
        payable(0xA12EEeAad1D13f0938FEBd6a1B0e8b10AB31dbD6).transfer(balance * 49 / 100);
        payable(0x5b58AEEbafE359fE5B19Ae3B41048Ab859f4Bc87).transfer(balance * 12 / 100);
        payable(0x853B28a4A0cFc0DBAf5349824063Eb5DB54775C1).transfer(balance * 5 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 8 / 100);
        payable(0x9db13B06345c1bf5684f02aA2022103e11B3a702).transfer(balance * 8 / 100);
        payable(0x11CaFe39a4d956c0c9ed0EE780e83A8245885917).transfer(balance * 8 / 100);
        payable(0xeFA6F0951E1F8Df2F8EBf2D879ac6A137688fE4B).transfer(balance * 5 / 100);
    }
}