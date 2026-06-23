Proyecto PichangApp
﻿
## Descripción 
  Este proyecto está orientado a juntar personas que no tienen un grupo deportivo, por diversos casos, PichangApp facilita la interacción entre personas que tiene los mismos intereses deportivos.
 
## Tecnologías utilizadas 
La aplciación está desarrollada por partes, en la parte de Frontend está desarrollada en lenguaje Flutter en Visual Studio, para darle compatibilidad tanto con android y IOs.
En la parte de Backend, Desarrollado en Intellij, está pensado en una arquitectura de microservicios, para generar dasacoplamiento entre las partes, para asegurar que la app siga corriendo en caso que falle una parte de esta, a su vez también cuenta con una arquitectura orientada a eventos mediante RabbitMQ en algunos microservicios como "msvc-comunicacion".
Todo este backend corre desde un docker en AWS para que este permanentemente funcionando.
Como Bases de datos usamos supabase con una PostgreSQL, para asegurar rapidez, seguridad y robustez.
 
## Requisitos previos 
Frontend:
- Flutter 3.35 o superior
- Dart SDK 3.9 o superior
- Visual Studio Code u otras Ides de desarrollo

Backend:
- Java 21
- Maven 3.9+
 
## Instalación 
  Para instalar el frontend se debe importar el repositorio https://github.com/Matias-Segovia-fullstack/PichangApp_FrontEnd.git y correrlo desde la rama main.
  A su vez el backend corre en un docker de AWS permanentemente, pero de igual forma se puede importar el repositorio https://github.com/lucmachuca/PichangApp.git y correr desde la rama "gestion"
 
## Configuración 
  El proyecto no cuenta con variables .env,solamente estas partes antes mencionadas.
 
## Uso / Ejecución 
  Como fue mencionado anteriormente, el backend esta corriendo permanentemente en AWS, mientras que el Frontend se puede correr tanto por la app generada por Flutter o desde el proyecto mismo del frontend. 
 
## Arquitectura del proyecto 
  Como fue antes mencionado, es un proyecto FullStack de Frontend y Backend, además de tener una base de datos contenida en supabase. El Backend tiene una arquitectura de msvc, con algunos microservicios orientados a eventos.
 
## Base de datos 
En nuestra base de datos supabase, tenemos diversas tablas (mostradas en el informe), las principales son "users" para contener a los usuarios, "users_profile" que tiene todos los perfiles de los usuarios y permite su edición e "interacciones" que almacena todos los "likes y dislikes" dados por los usuarios. 
 
## Documentación de la API 
Endpoint de registro
@PostMapping("/register")
  public ResponseEntity<EntityModel<UserResponseDTO>> register(@Valid @RequestBody User user) {
    return create(user);
  }

Endpoint de login
@GetMapping("/me")
    public ResponseEntity<UserResponseDTO> me(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        return userService.findByUsername(authentication.getName())
                .map(user -> ResponseEntity.ok(userModelAssembler.toDto(user)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND).build());
    }

endpoint de interaccion
@PostMapping("/interacciones")
    public ResponseEntity<InteraccionResponse> interaccion(@Valid @RequestBody InteraccionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(matchService.registerInteraccion(request));
    }


endpoint de match
@GetMapping("/interacciones/usuarios-interactuados/{usuarioId}")
    public ResponseEntity<List<Long>> obtenerUsuariosInteractuados(
            @PathVariable Long usuarioId
    ) {
        return ResponseEntity.ok(matchService.obtenerUsuariosInteractuados(usuarioId));
    } 
 
## Estructura del equipo / Autores 
-Rodrigo Rojas: Product Owner y desarrollador principal de Backend
-Luciano Machuca: Scrum Master y experto en las bases de datos y RabbitMQ
-Matías Segovia: Desarrollador principal de Frontend y seguridad de JWT
 
## Tests / Pruebas 
Para ejecutar las pruebas del Frontend se debe ingresar al proyecto y ejecutar el comando "flutter test", con eso correrán todas las pruebas a la vez. Para el backend debe ingresar al msvc especifico, dirigirse a la carpeta "test", donde se encontraran todos los test, para correr los archivos en solitario
 
## Licencia 
Proyecto desarrollado con fines académicos.
Todos los derechos reservados a DuocUC. 
 
Nota: el archivo README mejora la calidad documental del informe y es muy recomendable. 