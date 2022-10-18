// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library PaymentSplitterHelper {
    struct Payee {
        address wallet;
        uint256 shares;
        Identity owner;
    }

    enum Identity {
        SNEAKY,
        LLAMA,
        AURA,
        CONNOR,
        HARASSMENT,
        KFNC,
        KFNC2,
        LINKO,
        TREASURY,
        CHARITY
    }

    uint256 internal constant TOTAL_SHARES = 1000;

    function payeesAndShares() public pure returns (address[] memory, uint256[] memory) {
        Payee[] memory payeeData = _payeeData();

        address[] memory _payees = new address[](payeeData.length);
        uint256[] memory _shares = new uint256[](payeeData.length);
        uint256 totalShares;
        for (uint256 i = 0; i < payeeData.length; i++) {
            _payees[i] = payeeData[i].wallet;
            _shares[i] = payeeData[i].shares;
            totalShares += payeeData[i].shares;
        }
        require(totalShares == TOTAL_SHARES, "nope");
        return (_payees, _shares);
    }

    function _payeeData() private pure returns (Payee[] memory) {
        Payee[] memory payeeData = new Payee[](8);
        // payeeData[0] = Payee(0x1980c5a48909811200977D41C1E28a4bA32537F6, 100, Identity.CHARITY);
        payeeData[0] = Payee(0xBdD95ABE8a7694CCD77143376b0fBea183E6a740, 450, Identity.SNEAKY);
        payeeData[1] = Payee(0x0f2EB30Fb51771e2636574D29E369B4f32D88731, 55, Identity.LINKO);
        payeeData[2] = Payee(0x440b4a49248F25a9cF514aD8c1557CbF504ED5C4, 45, Identity.AURA);
        payeeData[3] = Payee(0xe66e39343d48aF67fb1679697FCA58b08B638459, 45, Identity.HARASSMENT);
        payeeData[4] = Payee(0x0b9d6CF696877551492BCbFECF6891f9B96aC868, 45, Identity.LLAMA);
        payeeData[5] = Payee(0x6b611D278233CB7ca76FD5C08579c3337C01e577, 30, Identity.CONNOR);
        payeeData[6] = Payee(0x1A20411c08c436387Bce1182bc224A0774FE54Ca, 20, Identity.KFNC);
        // payeeData[8] = Payee(0x9619da520414812Fd3794A6E8A55464c37691574, 10, Identity.KFNC2);
        payeeData[7] = Payee(0x306126f43f1086C1d388257bD3A64423bBa6A485, 310, Identity.TREASURY);

        return payeeData;
    }
}