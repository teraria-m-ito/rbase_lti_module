// 学部 select に紐づく学科 select（inline の外側 form-group 優先、モーダル等は広いコンテナで解決）
function relatedDepartmentSelects($inst) {
  var $inlineBlock = $inst.closest(".form-group.form-inline, .form-inline");
  var $inInline = $inlineBlock.find("select.select_department");
  if ($inInline.length > 0) {
    return $inInline;
  }
  var $g = $inst.closest(".form-group");
  var $inGroup = $g.find("select.select_department");
  if ($inGroup.length > 0) {
    return $inGroup;
  }
  var $scope = $inst.closest("form, .modal-body, .modal-content, .card-body");
  if ($scope.length > 0) {
    return $scope.find("select.select_department");
  }
  return $("select.select_department");
}

function stripLegacyOptionSpanWrappers($depts) {
  $depts.each(function() {
    var selectEl = this;
    $(selectEl).find("option").each(function() {
      var p = this.parentElement;
      while (p && p !== selectEl && p.tagName && p.tagName.toLowerCase() === "span") {
        $(this).unwrap();
        p = this.parentElement;
      }
    });
  });
}

function syncDepartmentOptionsVisibility($inst, $depts) {
  var selected = ($inst.val() || "").toString();
  if (selected === "") {
    $depts.find("option").each(function() {
      this.removeAttribute("hidden");
      this.disabled = false;
    });
    return;
  }
  $depts.find("option").each(function() {
    var opt = this;
    if (opt.value === "") {
      opt.removeAttribute("hidden");
      opt.disabled = false;
      return;
    }
    var attr = opt.getAttribute("data-parent-org-id");
    if (attr === null || attr === "") {
      opt.removeAttribute("hidden");
      opt.disabled = false;
      return;
    }
    if (String(attr) === selected) {
      opt.removeAttribute("hidden");
      opt.disabled = false;
    } else {
      opt.setAttribute("hidden", "hidden");
      opt.disabled = true;
    }
  });
}

function initSelectInstDept() {
  console.log("initSelectInstDept");
  $("select.select_institution").each(function() {
    var $inst = $(this);
    var $depts = relatedDepartmentSelects($inst);
    if ($depts.length === 0) {
      return;
    }
    stripLegacyOptionSpanWrappers($depts);
    syncDepartmentOptionsVisibility($inst, $depts);
    $depts.each(function() {
      var $sel = $(this);
      var opt = $sel.find("option:selected").get(0);
      if (opt && (opt.hidden || opt.disabled)) {
        $sel.val("");
      }
    });
  });
}

function selectInstDept() {
  console.log("selectInstDept");
  $(document).off("change.eportSelectInstDept", ".select_institution");
  $(document).on("change.eportSelectInstDept", ".select_institution", function() {
    console.log("selectInstDept->change");
    var $inst = $(this);
    var $depts = relatedDepartmentSelects($inst);
    stripLegacyOptionSpanWrappers($depts);
    syncDepartmentOptionsVisibility($inst, $depts);
    $depts.val("");
  });
}

// lms_users_controller 等は import { RbaseLtiModuleCommon } を使用するため名前付きで公開する
export const RbaseLtiModuleCommon = {
  initSelectInstDept,
  selectInstDept,
};