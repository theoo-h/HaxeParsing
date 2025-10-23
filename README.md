pequeño proyecto para aprender el hacer tokenizacion, parseo y interprete de un mini lenguaje de scripting

## TODO
- [x] parsear stacks de elifs y else
- [x] parsear And y Or
- [x] parsear llamadas a funciones
- parsear +=, *=, /=, -=
- orientacion a objetos
- añadir pos info a todo lo que se pueda en el parser

## Hecho
- Tokenizacion
- Parser (in progress)
    - Precendencia (logica) (80%)
    - Statements (50%)
        - Ifs
        - For (2 tipos, iterador (in) y condiciones (inicializacion/referencia; condicion; aumentar))
        - While
    - Expresiones (90%)
        - var decl
        - fun decl
    - Bloques (100%)
- Interprete (sin empezar)