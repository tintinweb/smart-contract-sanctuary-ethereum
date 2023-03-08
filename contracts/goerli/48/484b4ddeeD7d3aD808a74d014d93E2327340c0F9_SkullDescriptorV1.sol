// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Base64.sol';
import "./ISkullDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SkullDescriptorV1 is ISkullDescriptor {
    struct Trait {
        string content;
        string name;
    }
    using Strings for uint256;

    string private constant SVG_END_TAG = '</svg>';

    function tokenURI(uint256 tokenId, uint256 seed) external pure override returns (string memory) {
        Trait memory headwear = getHeadwear(((seed >> 6) % 9) + 1);
        Trait memory eyes = getEyes(((seed >> 3) % 6) + 1);
        Trait memory body = getBody((seed % 7) + 1);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                body.content,
                eyes.content,
                headwear.content,
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = '';

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"Friend #', tokenId.toString(), '",',
                            '"description":"', description, '",',
                            '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                            '"attributes": [{"trait_type": "Body", "value": "', body.name, '"},',
                            '{"trait_type": "Eyes", "value": "', eyes.name, '"},',
                            '{"trait_type": "Headwear", "value": "', headwear.name, '"},',
                            ']',
                            '}')
                    )
                )
            )
        );
    }

    function getBody(uint256 seed) private pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 1) {
            content = '<image x="43" y="101" width="234" height="219" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOoAAADbCAYAAABjsg1GAAADv0lEQVR4nO3doXEbURRA0VXGFXhJYHC6cA8mBi7FAXYpBibuwV0EB4aoBmVCwhLwf1bra53DV9rV6s5Hb97hdDot/Nu6rn6kbR1GPv14PIYecc6n8s3DpRAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoUAoULARY25jY6r3dw/Dn/n5y9fh6+9FC9Pt6NPOjQetwRH5JyoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoWA3JjbzGa1mXG1UcbctjMxHrfUNsg5USFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAnabntljYdMeTM+8T7XFVE5UCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFgCsvaVs/f3z/yI/3h61123KiQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoEmJ7ZmKkS/gcnKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChYCpJVHrup68ZC7M8H9+XdfD6LVOVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCwNXMqNrN/ePZn/Dt+dvwtXvcL9t5ebod/uy7h9ezv5mXp9vh1pyoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBU0uiZoxOwdzcPw4v2nl7/jY0vWDqZlujUzB3D6/D/4XRSZY9pm4WJyo0CBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIeD3mNvZx8ZqZhZT8bFMLqYabs2JCgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQcLi+vh6+yz2WJ01Ospx9MdAeC5Bm7LE8aWIi5ey/kSVRwF8JFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAh4Op4PA7f5bqu3vFGZpYR8fHeixMVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCHgcDoN7QRKWte19LDDC5AmJ6L8Ru+QExUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCo8N4ty/ILNn1tzSsP+aMAAAAASUVORK5CYII="/>';
            name = "Blue";
        }
        if (seed == 2) {
            content = '<image x="43" y="101" width="234" height="219" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOoAAADbCAYAAABjsg1GAAADuUlEQVR4nO3dsW3bQBiAUSnwBGaVwo377KAN0htI4wkEqPMOAgSkd+k5NEmaFKk4g4I0KVMcY9Of9V5/Io/Uh6t+cHu5XDZrmKZpjQtvRxbN8zx8wZX2uYahZ7tZ8HzXeLbzPA/vc5qm4et+Gl4JvBmhQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoE3NRe0vPhYXjt4/FlaCxqyXjS+XQYXluy2x+HR85Gn++SZ7vbH4fXrsGJCgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIyI25LbFkRI5/u5ZxvrU4USFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIuPGSXtePn78+8vb+ur/7/E7u5GNyokKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBJieeWWmSvgfnKgQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUCfCQK3sg8z8MXcqJCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQIWjblN03TxkrkmC//z29GFTlQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChYCbJdMAz4eH4R0+Hl/8P8g5nw7Dt7zbH4dbc6JCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIuKm9JB+X4ho5USFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAdvb29vLGrf5fHjYjqx7PL4M3+/z4WFo3ZLRutF93t99Hr7mGnb74/B7OZ8OQ+t2++PwTs+nw9B7WbLPJZyoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBfz4SNTRFsFkwjXJNvj59H9rtNE3X/uhe1ZdvT0M/f17QyxJOVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKHCe7fZbH4DWDpJ8uqhLMEAAAAASUVORK5CYII="/>';
            name = "Brown";
        }
        if (seed == 3) {
            content = '<image x="72" y="87" width="176" height="233" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAALAAAADpCAYAAACENr1hAAADQElEQVR4nO3csZHaUBRAUfBQwaoHZaqGOlUNmXpQDXg2cWrPx4v2rs7JBe+jOz96w/X5fF6OME3TMV/MV7mOfu6+78Mj/fI6KRMwaQImTcCkCZg0AZMmYNIETJqASRMwaQImTcCkCZg0AZP20jrlKyuR67q+/Xeb5/nt33kWy7K8ctLhVUw3MGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTdv34+EhtlL3CNtr39MommxuYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTdjvT69u27RtM8fXmef7pR/zDDUyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApJ1qG+1MW1pn4QYmTcCkCZg0AZMmYNIETJqASRMwaQImTcCkCZg0AZMmYNIETJqASRMwaQImTcCkCZg0AZMmYNIETJqASRMwaQImTcCkCZg0AZMmYNIETJqASRMwaQImTcCkCZg0AZMmYNIETJqASRMwaQImTcCkCZg0AZMmYNIETJqASRMwaQImTcCkCZg0AZMmYNIETJqASRMwaQIm7eb1/Tzbtg2faZ7n1O/hBiZNwKQJmDQBkyZg0gRMmoBJEzBpAiZNwKQJmDQBkyZg0gRMmnXKf3Cm9cQaNzBpAiZNwKQJmDQBkyZg0gRMmoBJEzBpAiZNwKQJmDQBk3bYNtr9fh96bl3X/z7L34zO+unxeAw/O7oFd9S8R3ADkyZg0gRMmoBJEzBpAiZNwKQJmDQBkyZg0gRMmoBJEzBpAiYt9+d+tVXBZVmGnz1idXR03qPWMN3ApAmYNAGTJmDSBEyagEkTMGkCJk3ApAmYNAGTJmDSBEzabd/36+gBpml6vvvw67oOz7ssy9vnfTwep5j3iFkvbmDqBEyagEkTMGkCJk3ApAmYNAGTJmDSBEyagEkTMGkCJk3AdF0ul98AnEK4JiI+7QAAAABJRU5ErkJggg=="/>';
            name = "Ghost";
        }
        if (seed == 4) {
            content = '<image x="43" y="116" width="234" height="204" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOoAAADMCAYAAAB9YT9lAAADs0lEQVR4nO3dO27bQBRAUSpQ5U5myUWk9468Iu9IfRahUlDnVkFiIF2AYGiJvtE5PaXh52Kqh9ldr9fpUczzXLrZ3eiF5/N5+E89o6/pW2q18KCECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQkBtzWzOG9XY4fO5i/sH3p6eh615Opzuv9MNxWTb53xErn9HQiNxW43F2VAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFgM2mZ0anYLaYgFljdHqG21oxebPJwVR2VAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChYC9l3RbP97f/+fb+8OpdbdlR4UAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCDA9c2OmSvgMdlQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQsCqMbd5nq9eMg9m+Juf53k3eq0dFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhYL9mAubtcLj7Hb5eLsPXbrFebufldBr+7eOy3P3NvJxOw63ZUSFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAasOiVpjdFzt7XAYPmjn9XIZGjMyHndbo+Nqx2UZ/hZGR862GI+b7KjQIFQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgG/pmfuPo1Ss+ZgquPT0yM8olUHNpWsPJhquDU7KgQIFQKECgFChQChQoBQIUCoECBUCBAqBAgVAoQKAUKFAKFCgFAhYPf8/Dy8yi0OT1ozcjZN090PiRpd71aHEa04sOnu/7lmRHOUQ6KAvxIqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoWA/fl8Hl7lPM/e8Y08yqFLNVu9FzsqBAgVAoQKAUKFAKFCgFAhQKgQIFQIECoECBUChAoBQoUAoUKAUCFgv2aJa0bktlAayzsuy90PQJo+xriGDtKqqX27dlQIECoECBUChAoBQoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChYDd9foQwxK/zfNcutlNpmemaXqIZ2R6Bvh0QoUAoUKAUCFAqBAgVAgQKgQIFQKECgFChQChQoBQIUCoECBU+OqmafoJ7WV0rlWa0cAAAAAASUVORK5CYII="/>';
            name = "Heart";
        }
        if (seed == 5) {
            content = '<image x="15" y="73" width="291" height="247" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAASMAAAD3CAYAAABW+DKgAAAE2UlEQVR4nO3cMU7dWhRAUfOFItFT0SFFzCMNI8owGBFN5oEipaOiR0rzvtL88hOdG/B23lq9hZ9ttm5zzsXpdNpIuvNa3s3TX/q7Du2fc38AQIMYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQmXXsO7WlkDcnOA33eOrB95J05GQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIKp/d8znb4fT95//fH6beF++R8Pt1dfdng+pv3f4GQEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkHBxOp3O5U1M14Bs01UgK2tA7q+vppfyhseX1/EjWlg/8rzwXs5i/YiTEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCSIEZBwxKn96fT9aPJ+W5i+X5m8//5zfClv+Pxp/oSmE/8L0/7bwsT/oab9nYyABDECEsQISBAjIEGMgAQxAhLECEgQIyBBjIAEMQISxAhIECMgQYyABDECEvZaITJdA7JNV4FM14BsC6tArAH5+0zXj0xXj2xr60emq0e2PdaPOBkBCWIEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQcLl4E3fD626mf/Drj9dv02vhiKbf/MPt1Zcdfu7T9EInIyBBjIAEMQISxAhIECMgQYyABDECEsQISBAjIEGMgAQxAhLECEgQIyBBjICEi9PpNF0Dsk1XgaysAbm/vppeOvb48vrh9/r95x/+Efzn86f5s9jjW5ia3uu2tn7kefo3nYyABDECEsQISBAjIEGMgAQxAhLECEgQIyBBjIAEMQISxAhIECMgQYyAhMtzeQ17TDAfbTvBufAtNDkZAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCT8WiHy9NE3Ml3DsC2uYjiSlTUX+Ba2xf+zbdueh9eNe+JkBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJIgRkCBGQIIYAQliBCRcLt7EoSb+j+T++mp0tyvT/ns825UtDHs8o6mdvtvp5P2v9zL63364nb2TzckIqBAjIEGMgAQxAhLECEgQIyBBjIAEMQISxAhIECMgQYyABDECEsQISBAjIGF1hcjUh68eWXRzsPulZ7zOY2q6BmRbXAUy5WQEJIgRkCBGQIIYAQliBCSIEZAgRkCCGAEJYgQkiBGQIEZAghgBCWIEJOw1tb9iOol817j93/P48nqE29zVGT2j0Te/x+T9CicjIEGMgAQxAhLECEgQIyBBjIAEMQISxAhIECMgQYyABDECEsQISBAjIEGMgP1t2/YvOHiJOd+2D6IAAAAASUVORK5CYII="/>';
            name = "Light Blue";
        }

        return Trait(string(abi.encodePacked(content)), name);
    }

    function getHeadwear(uint256 seed) private pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 1) {
            content = '<image x="87" width="146" height="131" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJIAAACDCAYAAABm8UKwAAAClElEQVR4nO3dPWoVURiA4YkkihAVg41xC25Aey3UXlfgblyFjVhr4zrcgaCNBPwJGC8YyQqUb15uDD5PP/dM7rw5zRy+u3N6err8D568eDr+Q/fvX17zDe1MLnp17+WaNbfu0oW6W/5ZQiIhJBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSQiJx4Y6RPHv9fHTD3z98Ga+5Of45vvbmg/3ppaPjJ8s5HUGxI5EQEgkhkRASCSGREBIJIZEQEgkhkRASCSGREBIJIZHYffj28ZrX/6M31O8evx0vuPlyMr72PGzez/5X9+7+2vrdrmnBjkRCSCSEREJIJIREQkgkhERCSCSEREJIJIREQkgkhERCSCR2Hrx5dB5TJMYDEg6O7xgi8QdHR0ej7+jax1vTJe1INIREQkgkhERCSCSEREJIJIREQkgkhERCSCSEREJIJHbXvPH9dvh560/BEIk/mz7T75++jte0I5EQEgkhkRASCSGREBIJIZEQEgkhkRASCSGREBIJIZEQEondNUcHlsPtP4S9G1dG1518/ZHfy9+YHgeZDoI4c22ZHw2asiOREBIJIZEQEgkhkRASCSGREBIJIZEQEgkhkRASCSGR2F3zIdNhBd8OP4/fbP8vQyTO42TF/u3r45+tsCOREBIJIZEQEgkhkRASCSGREBIJIZEQEgkhkRASCSGREBKJs2Mk46MDy7KMj4NMXbghEsP7PTg4GD+XzcfplXN2JBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSQiIhJBKrhkhMTw5Mh0+c2SwnoxMHm+Of4zXXmA692Fuurlh1+4M27EgkhERCSCSEREJIJIREQkgkhERCSCSEREJIJIREQkgkhMR6y7L8BuhHYjkIqjoVAAAAAElFTkSuQmCC"/>';
            name = "Cactus";
        }
        if (seed == 2) {
            content = '<image x="14" y="29" width="292" height="117" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAASQAAAB1CAYAAADnXJwKAAACvElEQVR4nO3csY3UQBiAUfvYCCEKoAICRAdItIFEC9cGGSEhESk9XAtUQAMQHZx0QouMEJDCanysv717L7c8Xns/TTL/PN0hy7KczMPO83z0xS7Lssn3sMWzTtP0YOSiZVmubn4p/HHmlwAqBAnIECQgQ5CADEECMgQJyBAkIEOQgAxBAjIECcgQJCBDkIAMQQIyBAnI2J3SSI7p16iKwCoONzpa4+J8/J7Pn9w/6lrXun499k7ffxhf7st309fBS+/UyJ5js0MCMgQJyBAkIEOQgAxBAjIECcgQJCBDkIAMQQIyBAnIECQgQ5CADEECMnan9ipObTrBFr4MnmP/9Gp8sd/244fgL6/HrjuxwQ8cwA4JyBAkIEOQgAxBAjIECcgQJCBDkIAMQQIyBAnIECQgQ5CADEECMgQJyBAkIGM3z/Mm8zyWZTE84j/Z3Rv7aS/34+s5W/E2vw9+gU8fjd+Tv9uqC3ZIQIYgARmCBGQIEpAhSECGIAEZggRkCBKQIUhAhiABGYIEZAgSkCFIQMbu4nybpYyeJt5iSsCak89vX4xd9/Hz6B1/Xns1fvGwTQ6HDxt9L2u+hVP6dvdvHt78Yg5ghwRkCBKQIUhAhiABGYIEZAgSkCFIQIYgARmCBGQIEpAhSECGIAEZggRkCBKQsdtqIaNjT9aMfxg1OqqC22fNt7DFt7vVGJFRdkhAhiABGYIEZAgSkCFIQIYgARmCBGQIEpAhSECGIAEZggRkCBKQIUhAxjx66v63o59e5t+ePT6tE97cOvPoA9khARmCBGQIEpAhSECGIAEZggRkCBKQIUhAhiABGYIEZAgSkCFIQIYgARmCBGTsVi5keMzACkaewOG2+I8Os0MCMgQJyBAkIEOQgAxBAjIECcgQJCBDkIAMQQIyBAnIECQgQ5CADEECMgQJaJim6Qc/n0uirF74DgAAAABJRU5ErkJggg=="/>';
            name = "Cowboy Hat";
        }
        if (seed == 3) {
            content = '<image x="87" y="43" width="146" height="88" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJIAAABYCAYAAAAeCK5cAAABsElEQVR4nO3dsWqUQRhA0V2JEhIRrCxMk5RJae8D+B4+nC9gH3tLW23WNkIwIrFQBO3lm0tWyDn97D8zXKaZgd1eXZ7/3MxtJyOfvvyw8MmZL+8uVta54l7s0YN2KtxXQiIhJBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSQiKx+oxkavS04o/RfI9PPsVL+Dc3u9Pp0DvfoxVOJBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSQiIhJBJCInGw8iO3Tz6Pxj26fj5+5rCv5yBT0/ne7E7He/Tw5Gg07sfu2/STTiQaQiIhJBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSS7f/U9NXA78dD8cdfp3fbK/4/nh2Ez+9wd8XJxIJIZEQEgkhkRASCSGREBIJIZEQEgkhkRASCSGREBIJIZHYyzOSZ6+vx2Nv3xymc/lfvTp7P57Z248v7nxVTiQSQiIhJBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQS26vL8/FfFcBfTiQSQiIhJBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSQmLdZrP5BXdmLXxFtAfzAAAAAElFTkSuQmCC"/>';
            name = "Crown";
        }
        if (seed == 4) {
            content = '<image x="29" y="72" width="262" height="103" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQYAAABnCAYAAADi6ux3AAACGElEQVR4nO3dMWoUYQCG4RkJaCOWFloJFgniCXICL+BVPIJXsbD1BHsCEbewzgEkldWIoIW8ksg/wd1xn6dfdjJJXv7m45+XZZm42TzPXtJ/ZFmW+dTfwW3uHffjAYcgDEAIAxDCAIQwACEMQAgDEMIAhDAAIQxACAMQwgCEMAAhDECcncorWTOd3r9/drcP8xeePn7wz7/zVKz5WziVybYTAxDCAIQwACEMQAgDEMIAhDAAIQxACAMQwgCEMAAhDEAIAxDCAMTmZtejk9lDTKc5Tte7i+HnWjHZHp5rH+JGeicGIIQBCGEAQhiAEAYghAEIYQBCGIAQBiCEAQhhAEIYgBAGIOY1y601l4OO+nR+7rfI5rzY7w/xyMOLTicGIIQBCGEAQhiAEAYghAEIYQBCGIAQBiCEAQhhAEIYgBAGIIQBiB+zzOHp9JYuiv345dsRPAVb9+ry0WZ+goeXn4c/68QAhDAAIQxACAMQwgCEMAAhDEAIAxDCAIQwACEMQAgDEMIAxNnWXsnoSvLl8/vDF3xaZvLLh93XoTXyllaZkxMD8CfCAIQwACEMQAgDEMIAhDAAIQxACAMQwgCEMAAhDEAIAxDCAMTwFPmnoQnqu7dPhr9wzXx6lNk1d2D48ujXb66GPne9uxj+X3FiAEIYgBAGIIQBCGEAQhiAEAYghAEIYQBCGIAQBiCEAQhhAEIYgN9N0/QdMpA4wH8RVrEAAAAASUVORK5CYII="/>';
            name = "Farmers Hat";
        }
        if (seed == 5) {
            content = '<image x="43" width="219" height="190" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAANsAAAC+CAYAAAC8unqpAAAD3UlEQVR4nO3dIW5cVxSA4ZfKLKGVCpLA1migWcg0SygJMOsKwszKwryCsoCQLqHyAgIHOVFIk6hSVRWWdip3AU11nvxPpv4+fn2fZ+bXJe/o3tvv98uR+Xr8uLvd2WTZ9YvnL6dbnl5cnk/Xjm02r/M9l+XtAfYc/xaunz19M1l3+urnb6Z7fjFdCIgNPktig4jYICI2iIgNImKDiNggIjaIiA0iYoOI2CAiNoiIDSLHOGKzxmwkYziac+PPl9+NxnM+fHw83XLdWI/xnE8ZP6uTDSJig4jYICI2iIgNImKDiNggIjaIiA0iYoOI2CAiNoiIDSJ3663/q6vZuu32qC7zePTw/XTpcv/8p9HEwKrLR+aXVRxiWmDMyQYRsUFEbBARG0TEBhGxQURsEBEbRMQGEbFBRGwQERtExAYRsUHkZOU289GTQ4xHbLf5lnfFijGZ5dhGZaacbBARG0TEBhGxQURsEBEbRMQGEbFBRGwQERtExAYRsUFEbBA5WfPm/vWzp2+ma+/KZQqH8OHj4/muwwsyTi8uRxdy/GOzma50sQYgNjgYsUFEbBARG0TEBhGxQURsEBEbRMQGEbFBRGwQERtExAaRkzVjCkd4mcJsnGi3O5tueD0cWVnj0cP349WrxnP4V042iIgNImKDiNggIjaIiA0iYoOI2CAiNoiIDSJig4jYICI2iJys3MYlF7dkzZv7a0z3XTPdML6UY34hx3KI366TDSJig4jYICI2iIgNImKDiNggIjaIiA0iYoOI2CAiNoiIDSJig8jaERtuyf1v343/8G+/zO4PufHg3V++0lviZIOI2CAiNoiIDSJig4jYICI2iIgNImKDiNggIjaIiA0iYoOIt/4/U388eTB+sJMnv87/qR++OpaP6Og42SAiNoiIDSJig4jYICI2iIgNImKDiNggIjaIiA0iYoOI2CAiNojc2+/3PutPm99UsdudTZZdv3j+crrllz++ni5dfv9+9LjL6cXl+XjTzWb6wG/Hex6Akw0iYoOI2CAiNoiIDSJig4jYICI2iIgNImKDiNggIjaIiA0i3vr/L66u5mu329nEwHBaYFk5MTB+e3/+5v7N5zt7e3+7HW95CE42iIgNImKDiNggIjaIiA0iYoOI2CAiNoiIDSJig4jYICI2iIgNIkZsbtt0PGc6mrOsG88Zj8pMx2TWMGIDiA0OSGwQERtExAYRsUFEbBARG0TEBhGxQURsEBEbRMQGEbFBxIjN/9N8PGdZ+lGZO8LJBhGxQURsEBEbRMQGEbFBRGwQERtExAYRsUFEbBARG0TEBhGxQWFZlr8BHu2F+zw+2EwAAAAASUVORK5CYII="/>';
            name = "Fire";
        }
        if (seed == 6) {
            content = '<image x="43" width="248" height="190" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAPgAAAC+CAYAAAAY0MJ6AAAECklEQVR4nO3dIY4cVxRA0a5oJAOHZANeQZTgEDObRAaDba8uCTYYmSTMxNhWVuANhMTAqKIBwSO9H0+l7pzDv6q7q68+enrbvu8X/n+2bVt5Mdv0oP9DyzcP/QeAMoFDmMAhTOAQJnAIEziECRzCBA5hAocwgUOYwCFM4BAmcAgTOIRdeblJ45nPbdtGo6ZHjJmujNTu+z76nsOf599njs9OucEhTOAQJnAIEziECRzCBA5hAocwgUOYwCFM4BAmcAgTOIQJHMKWpsmOWJBnOd7dfv7tp/HZty/fT3/g8ZjVwv9o5ZnTo6fiBocwgUOYwCFM4BAmcAgTOIQJHMIEDmEChzCBQ5jAIUzgECZwCBM4hB25fHA0Ijhdjnc52YK8lZHP777/dnz2+ubp6NzK6PD0mW9evDvV8sEjuMEhTOAQJnAIEziECRzCBA5hAocwgUOYwCFM4BAmcAgTOIQJHMIOmyZ79eHZ6NyvP/4xniA6YhJo+j3/+vPv8TNXzr59+X50bjoRxtflBocwgUOYwCFM4BAmcAgTOIQJHMIEDmEChzCBQ5jAIUzgECZwCBM4hG0rC/kWxy9HD56OX976/OnL+OyZPH7yaPxpp6OmKwsPp1be55sX7+79894mMzm00qgbHMIEDmEChzCBQ5jAIUzgECZwCBM4hAkcwgQOYQKHMIFDmMAh7LBpsiOWDx6xIG862bUyKbUyTXbExN3K552aTs1NlzMuGofmBocwgUOYwCFM4BAmcAgTOIQJHMIEDmEChzCBQ5jAIUzgECZwCBM4hC2Ni67Ytm304JWRz7ONbk49lCWLZ3PEwkM3OIQJHMIEDmEChzCBQ5jAIUzgECZwCBM4hAkcwgQOYQKHMIFD2NXKV5tOhF0WpsLOtliPux0x5Te1MhF2ffN0vq1zyA0OYQKHMIFDmMAhTOAQJnAIEziECRzCBA5hAocwgUOYwCFM4BAmcAi7HV+795HPy0FL+Y7w+dOX0Yjg4yePxu9l+syjTL/r2cZ/p6Om+76P36cbHMIEDmEChzCBQ5jAIUzgECZwCBM4hAkcwgQOYQKHMIFDmMAhbGn54Moitlcfnp3mVz3bdNYDsvJextN6Z+IGhzCBQ5jAIUzgECZwCBM4hAkcwgQOYQKHMIFDmMAhTOAQJnAIEziErS4fHI/rLSwfXBnzM/Z5h19++H107vXH5/f+Xs62fHD6310Zy3aDQ5jAIUzgECZwCBM4hAkcwgQOYQKHMIFDmMAhTOAQJnAIEziECRzCrvZ9P2SE8vXH5w/if7Uwfvmff5av7N7/Rwsjx0eNmo5+o+ubp+MHusEhTOAQJnAIEziECRzCBA5hAocwgUOYwCFM4BAmcAgTOIQJHMIEDlWXy+UfPHOqMEjZN0YAAAAASUVORK5CYII="/>';
            name = "Green hair";
        }
        if (seed == 7) {
            content = '<image x="87" y="43" width="146" height="45" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJIAAAAtCAYAAABF5zIuAAAAx0lEQVR4nO3cwQkCMRRAwax4sQVL0Kv9gxakJawtSPaxgs7cQ0h45PTJsq7rmPV6XOcXTzqdb3tv+U+W2bMe/v3maAiJhJBICImEkEgIiYSQSAiJhJBICImEkEgIiYSQSAiJxPK8X7aMgkyPHezN+MlHplvwIpEQEgkhkRASCSGREBIJIZEQEgkhkRASCSGREBIJIZEQEonjxlEQv5H8Fr+R8F1CIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSQiIhJBJCYrsxxhv9CgwSbxeutQAAAABJRU5ErkJggg=="/>';
            name = "Halo";
        }
        if (seed == 8) {
            content = '<image x="72" y="130" width="205" height="60" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAM0AAAA8CAYAAADFcj7VAAAA+0lEQVR4nO3dsQ3CMBBA0QRFrEDBJizOFmxBwQo0ocoA35GIEO/1bk7+cmPp5nVdJ/g399tj+OKf3BZoRAORaCASDUSigUg0EIkGItFAJBqIRAORaCASDUSigUg0EC17vkjD5vV+Ds/icr4eMcd59KCXBiLRQCQaiEQDkWggEg1EooFINBCJBiLRQCQaiEQDkWggEg1Ei4Hxw4a/9+/hpYFINBCJBiLRQCQaiEQDkWggEg1EooFINBCJBiLRQCQaiEQD0XLU92rYjG4cuJyvezZe2BoA3yIaiEQDkWggEg1EooFINBCJBiLRQCQaiEQDkWggEg1EooFimqYP+OkP+nSIONYAAAAASUVORK5CYII="/>';
            name = "Headband";
        }
        if (seed == 9) {
            content = '<image x="87" y="58" width="146" height="88" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJIAAABYCAYAAAAeCK5cAAABTElEQVR4nO3csW3EMBAAQb2hRKFS9V8bU5WgB1wCuW8Y+JmcTLi4iLjX8zzPNu+1cJb/Z7qFH49JQUgkhERCSCSEREJIJIREQkgkhERCSCSEREJIJIREQkgkhERCSCSEREJIJIREQkgkhERCSCSEREJIJIREQkgkhERCSCT2xUtmlw5YPvFZK4tBpphIJIREQkgkhERCSCSEREJIJIREQkgkhERCSCSEREJIJIREYr/ve/qe8zy9Ar9MJBJCIiEkEkIiISQSQiIhJBJCIiEkEkIiISQSQiIhJBKrSyRmrSw5+JYFFH++CGLlJ4iJREJIJIREQkgkhERCSCSEREJIJIREQkgkhERCSCSEREJIJPaVbxljjKmvDtd1eb0PGmNMXX4cx3QLJhIJIZEQEgkhkRASCSGREBIJIZEQEgkhkRASCSGREBIJIbFu27Y38aAWTTDn4koAAAAASUVORK5CYII="/>';
            name = "Horns";
        }

        return Trait(string(abi.encodePacked(content)), name);
    }

    function getEyes(uint256 seed) private pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 1) {
            content = '<image x="116" y="174" width="88" height="45" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFgAAAAtCAYAAAAqeqxGAAAApElEQVRoge3awQkDMQwAQV9K8PVfomtISAs2k3Cw8zdCi5+65pzvse/aebnWOhj5e/d9bzd6PWrTByowVmCswFiBsQJjBcYKjBUYKzBWYKzAWIGxAmMFxgqMFRgrMFZgrMBYgbECYwXGCowVGCswVmCswFiBse915T/mnlx0nti6Bj3RD8YKjBUYKzBWYKzAWIGxAmMFxgqMFRgrMFZgrMDSGOMDHooGxN0JpgQAAAAASUVORK5CYII="/>';
            name = "Admired";
        }
        if (seed == 2) {
            content = '<image x="116" y="174" width="88" height="30" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFgAAAAeCAYAAAColNlFAAAAkklEQVRoge3YwQmAMAxA0SqevHYON3MGxc2cQUdwBr3qDglfKPx3DyWfntItx/2WuC4yuU1j4sn/recTbtQ3tWmDDAwzMMzAMAPDDAwzMMzAMAPDDAwzMMzAMAPDDAwboifHjFpr5kSaEdp13q9wI38wzMAwA8MMDDMwzMAwA8MMDDMwzMAwA8MMDDMwzMCkUsoHwpAKzD4mPigAAAAASUVORK5CYII="/>';
            name = "Blue Eyes";
        }
        if (seed == 3) {
            content = '<image x="101" y="174" width="118" height="30" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHYAAAAeCAYAAAD5AOomAAAAg0lEQVRoge3Z0Q3AIAgAUewIsP+IzFDTFUwa4uXeAqgXv1iZ+caMdTK1u4eOe6aqRt73mRiq/xkWyrBQhoUyLJRhoQwLZVgow0IZFsqwUIaFMiyUYaG+td1tN7tqzTjFHwtlWCjDQhkWyrBQhoUyLJRhoQwLZVgow0IZFsqwUIYliogNg2MGprcVebEAAAAASUVORK5CYII="/>';
            name = "Bruh Eyes";
        }
        if (seed == 4) {
            content = '<image x="116" y="145" width="88" height="74" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFgAAABKCAYAAAA/i5OkAAAA8UlEQVR4nO3cwYnDMBBAUXlJA8b9l2i7BKeEwCyfEHjvPgz66KSDtud51tR936Phfd/HO79km679+7WT/hqBYwLHBI4JHBM4JnBM4JjAMYFjAscEjgkcEzj2mj45ri89Ox7HMZ49z3M6Om7kBscEjgkcEzgmcEzgmMAxgWMCxwSOCRwTOCZwTOCYwDGBYwLHBI4JHBM4JnBM4JjAMYFjAscEjgkcEzgmcEzgmMAxgWMCxwSOCRwTOCZwTOCYwDGBYwLHBI4JHNuu6/rPBl8rfuAGxwSOCRwTOCZwTOCYwDGBYwLHBI4JHBM4JnBM4NJa6w0s0RONUr/k2wAAAABJRU5ErkJggg=="/>';
            name = "One Eye";
        }
        if (seed == 5) {
            content = '<image x="116" y="174" width="88" height="30" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFgAAAAeCAYAAAColNlFAAAAjklEQVRoge3YwQmAMAxA0VbcoOCkvXQBO6Iz6BK6Q8IXCv/dQ8mnp9T7PN8SVyOTxxiJJ//3zBlutC216YIMDDMwzMAwA8MMDDMwzMAwA8MMDDMwzMAwA8MMDNujJ8eM1lrmRJoR2vXqPdzIHwwzMMzAMAPDDAwzMMzAMAPDDAwzMMzAMAPDDAwzMKmU8gHylwos7oew3QAAAABJRU5ErkJggg=="/>';
            name = "Red Eyes";
        }
        if (seed == 6) {
            content = '<image x="130" y="174" width="60" height="30" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAADwAAAAeCAYAAABwmH1PAAAAUUlEQVRYhe3PsREAMQjEQOwSoP8SqcHfw2Wv0ebModPdr3InvdzdeHRm4p9vvPpTBtMZTGcwncF0BtMZTGcwncF0BtMZTGcwncF0BtMZjFZVH0u4BXFLLMISAAAAAElFTkSuQmCC"/>';
            name = "Small Eyes";
        }
        if (seed == 7) {
            content = '<image x="116" y="174" width="88" height="30" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFgAAAAeCAYAAAColNlFAAAAgklEQVRoge3Y0QnAMAgAUdMRzP4jOkNLV1CuJXDvP4hHvlyZeUff6rysqsHI7+29242uozY9kIFhBoYZGGZgmIFhBoYZGGZgmIFhBoYZGGZgmIFh77nyj7mTE+lE67w64Q+GGRhmYJiBYQaGGRhmYJiBYQaGGRhmYJiBYQaGGZgUEQ9ArQambT2qLgAAAABJRU5ErkJggg=="/>';
            name = "Standard";
        }
        if (seed == 8) {
            content = '<image x="101" y="160" width="118" height="44" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHYAAAAsCAYAAACwskyAAAAAwElEQVR4nO3bwQ2AIBAAQTQ2QA/0XxEtACVobAEiFzc7f4Pchhfh6L3fKcYxs2rOOeh354wxQuZ7Riyq7xkWyrBQhoUyLJRhoQwLZVgow0IZFsqwUIaFMiyUYaGulW2VUrZPpbW2fc0VKzOqtU5/64mFMiyUYaEMC2VYKMNCGRbKsFCGhTIslGGhDAtlWKj3UVbIzhZuPX71iCyKJxbKsFCGhTIslGGhDAtlWCjDQhkWyrBQhoUyLJRhoQxLlFJ6AHrnEotxGOeXAAAAAElFTkSuQmCC"/>';
            name = "Stare";
        }
        if (seed == 9) {
            content = '<image x="116" y="145" width="88" height="88" xlink:href="data:img/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFgAAABYCAYAAABxlTA0AAABE0lEQVR4nO3dQQrDIBRAQS25/5XTOyhPW5jZC/kPV8HEOcZ4x6L3XV46VxfumHMuPfDGnOMTzIHA5wgcEzgmcEzgmMAxgWMCxwSOCRwTOCZwTODYc+vV4SXHZ7WDYwLHBI4JHBM4JnBM4JjAMYFjAscEjgkcEzgmcOzZOV254dYr0uOz2sExgWMCxwSOCRwTOCZwTOCYwDGBYwLHBI4JHBM4JnBM4JjAMYFjAscEjgkcEzgmcEzgmMAxgWMCxwSOXTmEt/Orwh1znh/XDo4JHBM4JnBM4JjAMYFjAscEjgkcEzgmcEzg2NantP92UcnqrC4q+WECxwSOCRwTOCZwTOCYwDGBYwLHBI4JHBM4JnBpjPEFg78Vq5LjLnAAAAAASUVORK5CYII="/>';
            name = "Trippy";
        }

        return Trait(string(abi.encodePacked(content)), name);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISkullDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}