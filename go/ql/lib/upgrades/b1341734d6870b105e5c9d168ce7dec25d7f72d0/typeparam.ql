class TypeParamType extends @typeparamtype {
  string toString() { none() }
}

class CompositeType extends @compositetype {
  string toString() { none() }
}

class TypeParamParentObject extends @typeparamparentobject {
  string toString() { none() }
}

from TypeParamType tp, string name, CompositeType bound, TypeParamParentObject parent, int idx
where typeparam(tp, name, bound, parent, idx)
select tp, name, bound, parent, idx, false
