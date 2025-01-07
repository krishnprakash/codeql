---
category: feature
---
* A new class `TemplateTemplateParameterInstantiation` was introduced, which represents instantiations of template template parameters.
* A new predicate `getAnInstantiation` was added to the `TemplateTemplateParameter` class, which yields instantiations of template template parameters.
* The `getTemplateArgumentType` and `getTemplateArgumentValue` predicates of the `Declaration` class now also yield template arguments of template template parameters.
