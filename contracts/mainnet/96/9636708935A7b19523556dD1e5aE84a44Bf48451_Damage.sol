// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Damage {
    struct DamageComponent {
        uint32 m;
        uint32 d;
    }

    uint256 public constant PRECISION = 10;

    function computeDamage(DamageComponent memory dmg)
        public
        pure
        returns (uint256)
    {
        return (dmg.m * dmg.d) / PRECISION;
    }

    // This function assumes a hero is equipped after state change
    function getDamageUpdate(
        Damage.DamageComponent calldata dmg,
        Damage.DamageComponent[] calldata removed,
        Damage.DamageComponent[] calldata added
    ) public pure returns (Damage.DamageComponent memory) {
        Damage.DamageComponent memory updatedDmg = Damage.DamageComponent(
            dmg.m,
            dmg.d
        );

        for (uint256 i = 0; i < removed.length; i++) {
            updatedDmg.m -= removed[i].m;
            updatedDmg.d -= removed[i].d;
        }

        for (uint256 i = 0; i < added.length; i++) {
            updatedDmg.m += added[i].m;
            updatedDmg.d += added[i].d;
        }

        return updatedDmg;
    }

    // This function assumes a hero is equipped after state change
    function getDamageUpdate(
        Damage.DamageComponent calldata dmg,
        Damage.DamageComponent calldata removed,
        Damage.DamageComponent calldata added
    ) public pure returns (Damage.DamageComponent memory) {
        Damage.DamageComponent memory updatedDmg = Damage.DamageComponent(
            dmg.m,
            dmg.d
        );

        updatedDmg.m -= removed.m;
        updatedDmg.d -= removed.d;

        updatedDmg.m += added.m;
        updatedDmg.d += added.d;

        return updatedDmg;
    }
}