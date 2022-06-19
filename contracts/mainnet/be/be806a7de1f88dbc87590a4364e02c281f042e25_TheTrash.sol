/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Base64 {
    string constant private B64_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory _data) internal pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = B64_ALPHABET;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}


contract TheTrashrenderer {
    string public constant IMAGE_DATA =
        "data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAKAAD/4QMsaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA2LjAtYzAwMiA3OS4xNjQ0ODgsIDIwMjAvMDcvMTAtMjI6MDY6NTMgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyMi4wIChXaW5kb3dzKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpERTc3N0NDN0VGQ0IxMUVDQTU2MEZBMUI3QzE0RkI5NiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpERTc3N0NDOEVGQ0IxMUVDQTU2MEZBMUI3QzE0RkI5NiI+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOkRFNzc3Q0M1RUZDQjExRUNBNTYwRkExQjdDMTRGQjk2IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOkRFNzc3Q0M2RUZDQjExRUNBNTYwRkExQjdDMTRGQjk2Ii8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+/+4ADkFkb2JlAGTAAAAAAf/bAIQAFBAQGRIZJxcXJzImHyYyLiYmJiYuPjU1NTU1PkRBQUFBQUFERERERERERERERERERERERERERERERERERERERAEVGRkgHCAmGBgmNiYgJjZENisrNkREREI1QkRERERERERERERERERERERERERERERERERERERERERERERERERE/8AAEQgB9AH0AwEiAAIRAQMRAf/EAHkAAAIDAQEAAAAAAAAAAAAAAAABAgMEBQYBAQEBAQEAAAAAAAAAAAAAAAABAgMEEAEAAQIDBgUEAgMBAQAAAAAAARECMXEDURIyBBQFIUFSEzNhgSIVkSNCgjSxJBEBAQEAAwEBAQEAAAAAAAAAAAERMQISE2EhA//aAAwDAQACEQMRAD8A6ABPI9xggBggBggBggBggBggBggAAAAAKAAACAEABKHUgBBUVIAdRUgqHUVIAdRUgB1FSApipBBIVIAYIxTBBAwAKAAAACBggBggBggBggBggBggBkZAAAKAAAAAAAAAAAAAgAAAAKAAgAAEAIKAAhAASoZAlQwQAwiASCJgYIAZomBgjRTBGimCApmQQMEYoAAAAIAAAAAKAAAAAAAAZGQgAAoAAAAAAAAAAgAAAAKAAgAAEBApUOqm7mNO2aTdESm8f3L/AKdTNvrNc+3bHq+q0vXH8l1Wl64/l4qga8Of0e16rS9cDqtL1R/LxdEotXyfR7LqtL1QXVafqh47dG6eU9vY9Tp+qB1On6oeP3Ti08nt67qdP1QOp0/VDyM2wW7C+T29d1Wn6oPqtP1Q8fRGYPJ7ey6rT9cDqtP1w8aE8nt7PqtP1Qnp6tupwzE5PFUdvsGF6Xrizvtd6poQkw6maJimZBFMyCKZkEDAAoAAAAIAAAAAKAAAAAGRkIAAKAAAAAAACAAAAAoAVRUABUqiGQqVVQykVKZVCeQ7j/035vXVeR7jFeZvzdOjl/pwjy2lbqV3vJou5XTiJmiHJRxNV0eE5Oji41ZSiUaN3L9s1deyNS2YpIMdRV0f0uvtgfpdfbCauVz94t+XR/S6+2CnsuvtgMrnb8jel0P0uvtgfpdfbCmMAdD9PrbYZeZ5a/lrotvxnYGJcjo26utbZf4xLu/quX9Ljdr8eZs+/wD49MI8nzNkaerdZbhEzEOr2HC9zudj++/OXQ7H4Rel4a68u5CSuJSq5uyYR3hvIqZoVOqKkaNTqjRmjU0UzIIGABQAEAAAAAAAAUAADIyEAAFAAAAAQAAAAFAUzEYm5ffJ/wDm/wBoWTaluTXQ9y3bA9y3bDxHjtFZ2unzcfr+Pb+5btgvct2w8VWdorO08H1/Htd+3bBb9u2HjPHaXjtXwn0/Hs9+3bBTfbth46K7R47TwfR67ft2w8tz815i/NUTUmMdu2tXJ/5NN2E5OVcjVpgvJ6LterZby9sTMRPi88cQlWXHrffs9UD37PVDyVBT6mL6et9+z1QU69nqh5HxE1MNet9/T9UD37PVDyUVOkmGvWe9Zthw+8XRdq20mvg59JKiprZ2uYjmba/X/wAem37dsPHCsiNfOT/dfnLf2W6Ii+rj+SVsCz+PWxfbtg9+3bDyZM416et37dsHF9u2Hj5kpmTyvt7Lft2wlv27YeKrO1Ks7U8r7e037dsDft2w8XWSmZTwfR7bft2wseFsmd6PHzh7WzhjKGe3XHTr21cEYSYdAZBAwAKAAgAAAAAoAAGRkIAAKAAIAAAAAAAKBy++f8/+0Om5nfP+f/aGuvLHbivLo1SqhvQ9DyLdO3exW26UTKnT1IjFbbrWxILfYtWxyln1U9RatjnLPqCXSWfUdJZ9S6ywdXYA6Sz6jo7PqnHMWz4pRqxIKp5KydpdDp/VfvwN+AUdFp/U+js+q7fg94FHR2fUuis+rTE1MGXotP6jodP6tJgz6fIad008V/6vS+qdl27NZXe/AKI7Vo/U47ToztaOotOOZtBn/UaP1H6fR+rT1Vo6q0Gb9ToxtOO16UbV/VWjqrQU/q9L6rP0+j9U45q2Zo3QDmz2bQ+pfptD6umQOb+m0Pqf6bQ+rogHO/TaH1ZO49u0+W0t+yta0d1zu8/8/wB4B5y3ijOHttPhjKHibeKM4e105/GMoc+7t/mtg0YScnYwRimCNFAAAABAAAAABTIyEAAAAAAAFAAABACBy++f8/8AtDpuX3z/AJv9oa68s9uK8vKtajuvQ8iMJFQwM0BUFkJKok6yDXZgtsc7enaN6doOrAcrenbJ7922QdRKHK37tsnv3bZB1rcU3Hi+7bI37tsg7FBRyfcu2yU6l22QdegcedS7bJe5dtkHZDjb922RN922QdgONN922S37tsg7QcTfu2ye/dtkHbsxh2YuimLxcal22VnuX7Z/kHsN6Npb0bXj51L9s/yU6t/qn+Qex3o2nvRth4z3b/VP8pe5dtn+QeyiYnBzu8/8/wB4cC3VvjC6f5OdS67wumZj6yCq3ijOHtLOGMoePim9GcPY2cMZQx2deidqSMJOTsZkEUwAimABQAAAAQAAAyMgAAAAAAAFAQAgAJQM3OcrbzWn7d00itWkpWM1xZ7DpR/nLhalu7Mxsl7ScHjdbinOXXrbXHvJOGeQJg4tmcG3Ign7V2xLp79gKoNZHL37D6e/YCvdG6u6fU2JRy2psBn3RutMcrqT5DpNXYDNRKy3emi7pNXYs0+U1YmtAVxoQl08bWmOV1NifS6mwGXp42jponzbOmv2HHL37AY+kt2jo7drb7F+w/Zv2AxdFbtPobZ85bfauONK4GHoLdsj9fbtlv8AauP27gc/9fbtkfr7dsuh7Vw9q4HP6C3bI6O3bLoe1ch7NwME8pbtlGeUt2uhOhfsRnl758gc/prdo9iG7pdTYj0upsBzrrd2aL+R5eOZ1Ny6aRSqvmLJsvmLsWvs/wA/2lKs5b47LpxNd6XWtikRGxGE3Ou0khwZBltI0TRTMgjRmQQMACgAIAAAAAAAAAAKAgBAASgAIQFIKVQpweO1uKc5ewuwl43Umt92cunVx7qVulirmKCJmMHRyamiMHO3rtp+5ftkHSg4cz3b9sj3r9sg6qyMHH96/bI96/bIO3Yk4fUakYXT/I6nV9Ug7acYOD1Wr6pPq9b1SDv2pvPRzmt65PrNb1yD0Aed63X9cjrdf1z/ACD0RPPdbr+uf5PrNb1yD0Aef6zW9cnHOa3rkHfNwOt1vXI67X9cg75uB12v65Ts53X9cg7hONPO6/rlHrtf1yDthxY53X9cied1vXIO2HDnndf1yq6/X9cgu7j805Lez/P9pYrtW7U/K+aztbe0fP8AaUqzl6OEkEmHaJGibLSRomipAjZaMEYpgjRQAAAAQAAAABQEAIACUABCAgFQECVkpcS/sm9Mzv4zsdtCW4zf68tzvJ9LdFta1irLEVdXvXyW5OZbi3HG8jcge3CdDpKor9uC3IW0lHdkEN0bqe7I3ZBXuDdWbs7C3J2AhunuQluTsSiy7YCvcgTZC3cu2FNk7AVbkH7cJ7spbk7AVRpQftwtiy7YNy7YCr24P24W+3dsHt3bAVRpxKXsxtWRZdXBPcu2Ap9mNqUaUR5rdydg3J2Ar3I2l7UbVu5Owbk7AVxpRtE6UbVsWTsG5OwFM6cUxZ9yrbdZNJ8GWJ8AbuU7Z7+nF+9T7Ohyfbum1N/er4UPtnwRnLdCNRM0TZbiRopMtJGiaNGZGy0YI0UwAimCMUAAAAABAAACVAAQgAJUBAlZBAmkCJoqzXB718tuTnWYuh3r5bcnO08W45XlfBiFerfNkVhUWhm6i4uouBrDNGvcv0L5vrUE4NKkCgIJ24MV2vdEzA6m+Ab0NTBjjmrz9+6fCQaFkCLYSoAtTZ9fVnSiJtZ+sv8AoDoBzus1PonHN3/QG6E2fldWdSJm7yaQIpS8nNu5y+sx4A3m5vW6n0OOd1J2A6JsNnN3zdEeDo0BVqcM5OS7OpEbs5OLUHoe1fBGcuhDndq+CM5dCBqJJIJMtRI0TZaiRomjSRomy0kaJopmQRTMgimCApkAIACUABCAEFQECVkECaQECVkI1NFplwu9fLbk52nxOh3n5LcnP0+Jpir1evwrFevwwIzxFUvbK3FYCulPBq5TzZrsWjlPMGoAA5l2MnFlfErsZWWYAhuU8RGMLL8FduMA6kQjVZGCqQUc3NbYzY4irXzXDGbLbiB+3ImKeC5VfjINvI4S11ZORwlqkEq1hxbsZzdmMHGuxnMDt0puipzpTbFVmlwpanCCrT4ozdulHE0+OM3ckFepwzk4dXc1OGcnCB6LtPwRnLfDn9p+CM5b4UTNE2WokaJo3EzRNlqJGibLSRomimZBGjMjRQAEAASgAIQEAqAgSoCBNMggSsggTTIRNFWXE7x8luTBZi3d4+S3JgsnxVlehzHDCcShzHDGYM8YrFVuKwEZxaOV82a7Fp5TzBpAAOddjKzTwVXYyt0sAO/BVGMLdThUxjAOrGCld5KZkFXM8MZs1uMNHM8MZs1uMA0Kr8ZXKL+KQbOSwlpZuSwuaQSt4XIuxnN17eFx7p8ZzBdp4JX8JaXCNThBDT4ozdmXF0uOM3em2AZ9ThnJxHe1bY3JycKgO/2r4Izlvhg7X8EZy3QqJGRo0aSJo1EjRNlqJGibLSRomjSRomy0ZkaKAAABBQECVDIEMggTSAgSsggTTIIErIRMmkcTvHyW5OfZi393+S3JhsxRF0I8xwxmlCHMcMAz24pq7cVgIXYtPKebNdi08p5g1AAHMuxlfpYKLsZXaXCCWpwqIxhdqcKm3GAdbyZ5aPJlnEFfM8MZs9mML9fgjNnsxgGtmvn8paWXU4pBt5GfCWvdY+R828EYwce7Gc3Y8nGuxnMGjRj8T1YpaNGfxS15/D7go0Yrfbm9Hfo3WxV53Q+S3N6rW4QYNW2dycnAei1uC7J52Qd3tfwRnLfDB2v4IzluhpEjRNFSNE0VI0TZbiSSJo1EjRNlpI0TRTMgy0YAASQklQAEqAgSoCBKyCBNMggSsggSoCNFplxO7/Jbkw6eLd3f5LcmHTxZVfCHMcMZpQjzHDGYM0YrFduKwELsWnlPNluxaeT8waqmicA5t2MrdLBTdjK7RwBLU4VFuMLtXhUW4xmDs+TLMNXkzzEgo5jgjNms4oaea8LIzZbOKAbWTU4pamTU4pBv7bETvVdFzu2f5OlQFU4S4l2M5u3d5uHdjOYNWhwpa/B90eX4UuZ4PuCjQ+S3N6vW4XktD5Lc4et1uEGPV4LsnnJei1Z/CcnnZB3u1/BGctzD2v4IzltbZSNE0VI0TRUjRNGkjRNlpI0TZaSNE0aSNE0UwQRRJCSVDIgrIIEqAgTTIIErIIBUBAmmQiZKji93+S3Jh08W7u3yW5MOnizWouQ5jhhZCHMcMZoM1uK1VbiuoCm7Fp5PzZ78WjlPMGg4RqlAObdjK/R4VF2Mr9CPxA9XhUW4xm0asfiz24wDsxgolf5M0yCnm+GM2S3GGrmuGM2W3GAaqs2pxS0M+pxSDods/wAnRc7tmFzogou83EuxnN27vNxbo8ZzBp0J/FLmPGz7oaHCnr8H3BRoR/ZbnD1mtwvKaHyW5w9Zq8IMOrH4Tk87L0mtwXZPNA73a/gjOW5h7X8EZy3NsGCMUzIIqRomjSRomyqRomjSRomy0kaJo0YIICSEk0mggSs6ZEFQECVkECaQyBKyCAVAQIRxu7fJbkxaeLZ3ef7LcmHSn8ma1GqIqr5mPxjNZbgr5nhjNFZbcV6m3FoBnvxaOU81F+MtHK+YLKp2z4K1luAOfdjK/QwUXYyv0OED1eFRbjDRq8Ki3GAdfyZpaqeDNMAo5nhjNltxhq5rhjNltxBeovxlbvK7vGQdDtmFzoOf23C50AUXebjTjLs3ebjTjOYL9HBZr8H3Q0OFbr8H3Bm0Pktzh6vW4XltD5Lc3qdbhBj1eC7J5yXotXguyeckHe7X8EZy2sPbPgjOW5uMGZBQzIIqQI0UzII0kaJstJGiaKkaJo0YIIaJIpCoCBNMggSoZAlQAErIIBUBACAjJRxO7/JbkxaXE293+S3Ji0uJi8tThqtwV8zwxmstwQ5nhjNFZbcWhntxaAUX4yv5TzZ7+KWjlPMFiyzBWtswBzrsZaNDhZ7sZaNDwtA9XhUW4xm0as/jLPbP5RmDteTNLQzzIM/N8MZsduMNnNeNsZstkflGYLd1Tdi3UY9TikG7tuFzouf23C5vBXd5uJdjObuXebh3R4zmDTocKfMcH3R0I/FLmfCz7go0J/stzh6nX4XldCf7Lc4eq1+EGPV4LsnnJei1eCcnn5B2+2fBGctzD2z4IzludIxTBADMggZkBUjRNFMyCNJGibKpBE0a1IEA0pISSs6ZAlQAgqAgFQEAqAgBAASgI0RHG7v8luTFo8Tb3b5LcmHS4mLy3OGu1DmeGM07UOZ4YzRWW3FoZ7cWgGe/ilo5TzZ78ZaOU8wWQtswVQtswBz7sZXaOCm7GV2lgCWrwyz28UZr9ThlTbjGYOyzNPkyTiCrmuGM2aziho5nhjNnsxgGyrHqcUtTLqcUg39twudBg7bhdm3gqunFxbsZzdi7zca7GcwauX4VnNx+H3V8vgu5v4/uDFofJbnD1evwvLaHyW5w9Vr8IMWrwTk4MxFHe1eCcnCmPAHY7b8MZy2sXbvhjOWx0jnTAAGCMUGRoAyMUwRopmiaNGaJopgggJISTTJkCAAEqAAlQyAVAAQgAABFJFRxu7fJbkw6WLd3b5IyYdPFzvLc4arcEOZ4YzSswR5jhjNFZrcV1VNuK2oKr8V/K+ai/Fq5KOIEoXaeCFF2lHgDl3cU5rtHhU38U5rtLAD1eGVFvFGa/U4ZUW8UZg7XkyTi1+TJIKeY4IzZ7cYaeZ4IzZrcYBoqzanFLSzanFIOh2zC50HP7bhc6AKLvNxrsZdq6MXFuxkGrl8F3OfH91PL4Luc+P7gxaHyW5w9Zr8Lyeh8lucPW6uAMWrwTk4U4PQavBOTgTgDrdu+GM5bGTt/wxnLW6RzpgBQGQQMACmCNAGQFMyCKZkEUwQASQkKgBBUABCAAKAEAAAEAAUCKSION3b5IyYbMW/u0f2RkwWR4ud5bnDTZgjzHDGaVmCPMcMZorNbisV24rAQuxauSjiZbsWrk/MFq/SwQWaeAORfxTmt0sFV/FOa3TwA9ThlVbHjGa27CVduMZg7NPBknFs8lEwDJzPBGbNbjDXzfDGbJbjANFGe+PylpZ7+KQb+24XN7B27C5vBVd5uJdjObv3R4S4N2M5g08vgv5z4/up5bh+6/m/j+4MWhH9lucPWXxWHldD5Lc3q78AZta38LsnnJnwel1uC7J5ibvAHZ7d8MZy2Qxdu+GM5bYdI50wRqAAIAyAGCMUwQQMACmCCBggKJAklQwQEABKGQAAACAAAAQUAABxu6/JGTDZHi6HdOOMmG1zvLcXW4IcxwxmnbgjzHDGaKzW4rVVuKwEL8WjlLqVZ78V/K+YNazTwVrNPAHJv4pzW6WCq/inNbpYAd+Eq7cYzW38MqreKMwdtTNq0ogGHnYpbGbHZjDf3CPxjNz7cYBrZr+KWirPfxSDf27C5vlg7bhc3gjOEuDdjObvThLg3YzmDXy3Cv5v4/uo5bh+6/m/j+4Mmh8lub1d7yeh8lub1dwKdb47speWep1vjuyl5QHc7b8MZy2wxdt+GM5bHSMUwAIYIAYIwAAFMEAMEaAMgKYIAJAkCAEFAAAABAYICAAAAAAAIHJ7pxxkw2tvdJ/sjJhtlitxfbghzHDGaduCHMcMZorNbitqqtxWAjfiv5XzZ7sWjlfMGldp4KVlk0gHLv4pzW6XCpv4pzX6PCB3x+MqreKM12pwyos4ozB2ztgk7I8AYe4xS23NzrcYdLufDbm5tuMA0VUX8UrlF/FIOj23C5vc/tuFzoAU4S4F2M5u9dPhLg3YzmDXy3D91/N/H91HLcP3Xc58f3Bk0J/stzh6u6Xk9H5Lc3q7gVa0/13ZS8o9VrR/XdlLy1AdrtvwxnLbDF234YzlshuMVIEFDBGAAAAAADIIGCMAZAUwQAyEgQAAAQAAAAACAwQAwQAyABx+6/JGTBZi3d1+SMmKzFmtRfbghzHDCduCHMcMIrPbishXbisBG/FfyvmouxaOV8waaJ2g4Byb+KVungqv4pzWaeAJXYSrs4ozWThKFkflGYO3CdqMLLI8Ac/ufDbm5tuMOp3WKW25uVbjANKi/ilcqujxkG7tuFzco7TZE2XzLZuQCicHDuxnN374iKvP3YzmDZy3Cu5z4/up5Xh+67m/j+4MWj8lucPWXPK6Mf2W5vV3QCrW+O7J5Z6nW+O7KXlQdnt3wxnLZDD2+f6YzlsiWtZTCNRU0SCNRU0SCNRU0SCNRU0SNCp1BII1FQSNGoqCQRqASkCZKoAFUqgdRVGoqaJVFUaiqauHUVRqDTEqiqINMOoqiDVxOpVIjTHK7pxxkxWYtvc+OMmOyPFBdbghzHDCcQjrWzdFIBljwT3zjQvnyHs37JBGZq08p5qfYv2L+WsutrWKA3UOIFADjX8U5pW37sUTu5fUm6aRJdNqemQL3K+FBZP5RmlHK6s/4ynbymrEx+M4g68LLJpCtO0GHus1ttzcuPCauv3DSu1LYi2K0lzuk1fTIF7sbEJurNVnS6vplK3kta7C2QdLs/jZe3bksva9C/Rtu34pVtBTdozMTLzd8flOb1dPB52/kdebpncnGQV6Wt7cUpVZrc17lu7ShdDr+iUv1/MeiQVaE/wBlucPWy81pchrxfbM2TSJemmAU60f13ZS8rR6zW+O7KXlAdTt/xRnLXDJyHxRnLXAGCAGCAh1FUQCVRUgB1OqIFSqKkASqKogEqhEKicyVRIAVIAAQCKAAAACKAAAAAGQIHL7nxxkyaeLT3P5IyZtDxuVGiDhPdg9yAS08B5nbbRCcQSuRgHALykykBCSMJAnp4rVFs0T35A0rcConZHgBSisujwVga7R81VFul4AtlWnKIHCdmKEJ2AmsVrAAABXr/Hdk8nL1mv8AHdk8ndgDqch8UNcMnIfFDVCKYAAAAQgYAAAAAahGAABgCBgEpgUSmCBEkgCIMAQMkUgYAgZAAAAIwDkd0+SMmbl5/Np7p8kZMmhdFt1ZVG6bqCb5iFU6tm0XalsxiCca0l7kq4ujaN6NoLrbqpKbL7YxlP3bNoNQVe/p+oe/p+oFsJKY19Pafv6e0Fpqo19Pafv6e0GqidmDP1Wl6oSt5vS9UAvuwVI3c3pU4oV9TpeqAaYhZps0c3o04oTt5zRj/KAakaKet0fXA63Q9cA0REpWRLPHPaHrhK3ntD1wDTSU2br9D1wOv0PXANRTNGbr+X9cFdz2hP8AnALde7+u7KXkpvej1ec0ZsuiLorR5uYkHX7f46MZy1wy9v8AhjOWuEUAwBAwBAwABgCMGBAwABhQgYBZKKckCJJUKgIhKhARJEgQMAiDAEDAERgHI7n8kZMD0WpoWak1uisq55PS9IOAl4O70mj6YHR6PphUcLwHg7vR6PpgdHo+mAcLwHg7vR6PpgdHpemBXC8D8Hc6PS9MDo9L0wDh+Cy2baOx0el6YHSaXpgHI3rRN0bHX6XS9MH0ul6YEcPeG99Hc6TS9MDpNL0wDhb30FYd3pNL0wXSaXpgVwqiru9JpemD6PR9MIOBMovQ9Ho+mB0ej6YUx5+pxLv9Ho+mB0ej6YDHBqKu/wBHo+mB0ej6YDHn6nEu90ej6YPo9H0wGODvHN1Xd6PS9MDo9L0wGKe3/DGctcQenp22RS2KQlRFRoKJUOgIUFE6CgiNBRKgoCNBRKh0BGgolQUFRodEqCgI0OiVBQEaBKgBKSolIURoVEiBEGEESSAIg6CgIhKhUAgdBQEQlQgIkqCgIg6CgEDoAIGAIGAKgoZgjQUSICoEiAqCiQBGh0MAKChmCNBRIAVBRIAjQbqRgjujdSAI0OhgCoKGAKgoZgjQUSoARodDAFQUSAFQUMAKChgUqAwByDkgIkiAiSICoVEhQEaFRKgoCNBRKhUAqEkBERQwCNBRKgoCNBRKgoCNBRKgoCNBRKhUFKgOgoBA6CgESVCoBAwgQMAADAAGoAAAMGBGAABgCBgCBgADAEDAEYMCBgCBgAABQAAMAIAjAEDJQgYAiSAiIoYBEUSoKAjQUSoVAKgodBQCoVEqCgFQUOgoBUKiVBQEaCiVBQEaCiVCoCNBRKgoCNBRKgoCNBRKgoCNBRKgoio0CVDoqIhKgoBGdBQUgZiEDApAwBGAABhAgYAgYAgYAAAAAAAAAAAAAAAAAgAAACgIAAAAAAEAAAAAAAAAAAAAAQAAACgACAACgAAAABgBAGAoAAAACAMAAAAAAAAAAAAAAFAAAAADAAP/2Q==";

    function render() external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"The Trash",',
                            '"description":"An epic item that activates mysterious monsters!",',
                            '"image":"',
                            IMAGE_DATA,
                            '"}'
                        )
                    )
                )
            );
    }
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)


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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)


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

// File: @openzeppelin/contracts/token/common/ERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)




/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)




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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)




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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)









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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: contracts/TheTrash.sol








interface IRenderer {
    function render() external view returns (string memory);
}

contract TheTrash is ERC1155, ERC2981, Ownable {
    uint32 public constant MAX_SUPPLY = 6000;

    address public _renderer;
    uint32 public _minted = 0;
    address public _allowedMinter;
    address public _burner;

    constructor(address renderer) ERC1155("") {
        _renderer = renderer;
        setFeeNumerator(750);
    }

    function mint(address to, uint32 amount) external {
        require(_allowedMinter == msg.sender, "TheTrash: ?");
        require(amount + _minted <= MAX_SUPPLY, "TheTrash: Exceed max supply");

        _minted += amount;
        _mint(to, 0, amount, "");
    }

    function airdrop(address[] memory tos, uint32[] memory amounts) external onlyOwner {
        require(tos.length == amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            _minted += amounts[i];
            require(_minted <= MAX_SUPPLY, "TheTrash: Exceed max supply");

            _mint(tos[i], 0, amounts[i], "");
        }
    }

    function burn(address who, uint32 amount) external {
        require(msg.sender == _burner, "TheTrash: ?");

        _burn(who, 0, amount);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return IRenderer(_renderer).render();
    }

    function setMinter(address minter) external onlyOwner {
        _allowedMinter = minter;
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    function setRenderer(address renderer) external onlyOwner {
        _renderer = renderer;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }
}