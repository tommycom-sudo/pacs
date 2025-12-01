package com.bsoft.hihis.queapp.dto.opQueDTO;

import com.bsoft.hihis.queapp.client.visQueClient.dto.ClinicalVisitInfoQueryResponse;
import com.bsoft.hihis.queapp.client.visQueClient.dto.InstancePositionInfoResponse;
import com.bsoft.hihis.queapp.client.visQueClient.dto.QueryQueuePatientListCountResponse;
import com.bsoft.hihis.queapp.client.visQueClient.dto.QueueInstanceResponse;
import com.bsoft.hihis.queapp.dto.QueueBasePatient;
import com.bsoft.superhub.boot.common.service.UserContext;
import com.bsoft.superhub.boot.swagger.annotation.RpcModel;
import com.bsoft.superhub.boot.swagger.annotation.RpcModelProperty;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.ObjectUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.BeanUtils;

@RpcModel(")
public class QueueRealTimeResponse {
  @RpcModelProperty(")
  private String organizationId;
  
  @RpcModelProperty(")
  private String tenantId;
  
  @RpcModelProperty(")
  private String triageDepartmentId;
  
  @RpcModelProperty(")
  private String queueId;
  
  @RpcModelProperty(")
  private String queueInstanceId;
  
  @RpcModelProperty(")
  private String name;
  
  @RpcModelProperty(value = ", refCode = "belongDepartmentId", example = "11", notes = ")
  private String belongDepartmentId;
  
  @RpcModelProperty(value = ", refCode = "departmentName", example = "11", notes = ")
  private String departmentName;
  
  @RpcModelProperty(")
  private Date queueDate;
  
  @RpcModelProperty(")
  private String dateGroupingId;
  
  @RpcModelProperty(")
  private Integer queueRoomWaitingNumber;
  
  @RpcModelProperty(")
  List<QueueBasePatient> clinicalRoom;
  
  public void setOrganizationId(String organizationId) {
    this.organizationId = organizationId;
  }
  
  public void setTenantId(String tenantId) {
    this.tenantId = tenantId;
  }
  
  public void setTriageDepartmentId(String triageDepartmentId) {
    this.triageDepartmentId = triageDepartmentId;
  }
  
  public void setQueueId(String queueId) {
    this.queueId = queueId;
  }
  
  public void setQueueInstanceId(String queueInstanceId) {
    this.queueInstanceId = queueInstanceId;
  }
  
  public void setName(String name) {
    this.name = name;
  }
  
  public void setBelongDepartmentId(String belongDepartmentId) {
    this.belongDepartmentId = belongDepartmentId;
  }
  
  public void setDepartmentName(String departmentName) {
    this.departmentName = departmentName;
  }
  
  public void setQueueDate(Date queueDate) {
    this.queueDate = queueDate;
  }
  
  public void setDateGroupingId(String dateGroupingId) {
    this.dateGroupingId = dateGroupingId;
  }
  
  public void setQueueRoomWaitingNumber(Integer queueRoomWaitingNumber) {
    this.queueRoomWaitingNumber = queueRoomWaitingNumber;
  }
  
  public void setClinicalRoom(List<QueueBasePatient> clinicalRoom) {
    this.clinicalRoom = clinicalRoom;
  }
  
  public boolean equals(Object o) {
    if (o == this)
      return true; 
    if (!(o instanceof QueueRealTimeResponse))
      return false; 
    QueueRealTimeResponse other = (QueueRealTimeResponse)o;
    if (!other.canEqual(this))
      return false; 
    Object this$queueRoomWaitingNumber = getQueueRoomWaitingNumber(), other$queueRoomWaitingNumber = other.getQueueRoomWaitingNumber();
    if ((this$queueRoomWaitingNumber == null) ? (other$queueRoomWaitingNumber != null) : !this$queueRoomWaitingNumber.equals(other$queueRoomWaitingNumber))
      return false; 
    Object this$organizationId = getOrganizationId(), other$organizationId = other.getOrganizationId();
    if ((this$organizationId == null) ? (other$organizationId != null) : !this$organizationId.equals(other$organizationId))
      return false; 
    Object this$tenantId = getTenantId(), other$tenantId = other.getTenantId();
    if ((this$tenantId == null) ? (other$tenantId != null) : !this$tenantId.equals(other$tenantId))
      return false; 
    Object this$triageDepartmentId = getTriageDepartmentId(), other$triageDepartmentId = other.getTriageDepartmentId();
    if ((this$triageDepartmentId == null) ? (other$triageDepartmentId != null) : !this$triageDepartmentId.equals(other$triageDepartmentId))
      return false; 
    Object this$queueId = getQueueId(), other$queueId = other.getQueueId();
    if ((this$queueId == null) ? (other$queueId != null) : !this$queueId.equals(other$queueId))
      return false; 
    Object this$queueInstanceId = getQueueInstanceId(), other$queueInstanceId = other.getQueueInstanceId();
    if ((this$queueInstanceId == null) ? (other$queueInstanceId != null) : !this$queueInstanceId.equals(other$queueInstanceId))
      return false; 
    Object this$name = getName(), other$name = other.getName();
    if ((this$name == null) ? (other$name != null) : !this$name.equals(other$name))
      return false; 
    Object this$belongDepartmentId = getBelongDepartmentId(), other$belongDepartmentId = other.getBelongDepartmentId();
    if ((this$belongDepartmentId == null) ? (other$belongDepartmentId != null) : !this$belongDepartmentId.equals(other$belongDepartmentId))
      return false; 
    Object this$departmentName = getDepartmentName(), other$departmentName = other.getDepartmentName();
    if ((this$departmentName == null) ? (other$departmentName != null) : !this$departmentName.equals(other$departmentName))
      return false; 
    Object this$queueDate = getQueueDate(), other$queueDate = other.getQueueDate();
    if ((this$queueDate == null) ? (other$queueDate != null) : !this$queueDate.equals(other$queueDate))
      return false; 
    Object this$dateGroupingId = getDateGroupingId(), other$dateGroupingId = other.getDateGroupingId();
    if ((this$dateGroupingId == null) ? (other$dateGroupingId != null) : !this$dateGroupingId.equals(other$dateGroupingId))
      return false; 
    Object<QueueBasePatient> this$clinicalRoom = (Object<QueueBasePatient>)getClinicalRoom(), other$clinicalRoom = (Object<QueueBasePatient>)other.getClinicalRoom();
    return !((this$clinicalRoom == null) ? (other$clinicalRoom != null) : !this$clinicalRoom.equals(other$clinicalRoom));
  }
  
  protected boolean canEqual(Object other) {
    return other instanceof QueueRealTimeResponse;
  }
  
  public int hashCode() {
    int PRIME = 59;
    result = 1;
    Object $queueRoomWaitingNumber = getQueueRoomWaitingNumber();
    result = result * 59 + (($queueRoomWaitingNumber == null) ? 43 : $queueRoomWaitingNumber.hashCode());
    Object $organizationId = getOrganizationId();
    result = result * 59 + (($organizationId == null) ? 43 : $organizationId.hashCode());
    Object $tenantId = getTenantId();
    result = result * 59 + (($tenantId == null) ? 43 : $tenantId.hashCode());
    Object $triageDepartmentId = getTriageDepartmentId();
    result = result * 59 + (($triageDepartmentId == null) ? 43 : $triageDepartmentId.hashCode());
    Object $queueId = getQueueId();
    result = result * 59 + (($queueId == null) ? 43 : $queueId.hashCode());
    Object $queueInstanceId = getQueueInstanceId();
    result = result * 59 + (($queueInstanceId == null) ? 43 : $queueInstanceId.hashCode());
    Object $name = getName();
    result = result * 59 + (($name == null) ? 43 : $name.hashCode());
    Object $belongDepartmentId = getBelongDepartmentId();
    result = result * 59 + (($belongDepartmentId == null) ? 43 : $belongDepartmentId.hashCode());
    Object $departmentName = getDepartmentName();
    result = result * 59 + (($departmentName == null) ? 43 : $departmentName.hashCode());
    Object $queueDate = getQueueDate();
    result = result * 59 + (($queueDate == null) ? 43 : $queueDate.hashCode());
    Object $dateGroupingId = getDateGroupingId();
    result = result * 59 + (($dateGroupingId == null) ? 43 : $dateGroupingId.hashCode());
    Object<QueueBasePatient> $clinicalRoom = (Object<QueueBasePatient>)getClinicalRoom();
    return result * 59 + (($clinicalRoom == null) ? 43 : $clinicalRoom.hashCode());
  }
  
  public String toString() {
    return "QueueRealTimeResponse(organizationId=" + getOrganizationId() + ", tenantId=" + getTenantId() + ", triageDepartmentId=" + getTriageDepartmentId() + ", queueId=" + getQueueId() + ", queueInstanceId=" + getQueueInstanceId() + ", name=" + getName() + ", belongDepartmentId=" + getBelongDepartmentId() + ", departmentName=" + getDepartmentName() + ", queueDate=" + getQueueDate() + ", dateGroupingId=" + getDateGroupingId() + ", queueRoomWaitingNumber=" + getQueueRoomWaitingNumber() + ", clinicalRoom=" + getClinicalRoom() + ")";
  }
  
  public String getOrganizationId() {
    return this.organizationId;
  }
  
  public String getTenantId() {
    return this.tenantId;
  }
  
  public String getTriageDepartmentId() {
    return this.triageDepartmentId;
  }
  
  public String getQueueId() {
    return this.queueId;
  }
  
  public String getQueueInstanceId() {
    return this.queueInstanceId;
  }
  
  public String getName() {
    return this.name;
  }
  
  public String getBelongDepartmentId() {
    return this.belongDepartmentId;
  }
  
  public String getDepartmentName() {
    return this.departmentName;
  }
  
  public Date getQueueDate() {
    return this.queueDate;
  }
  
  public String getDateGroupingId() {
    return this.dateGroupingId;
  }
  
  public Integer getQueueRoomWaitingNumber() {
    return this.queueRoomWaitingNumber;
  }
  
  public List<QueueBasePatient> getClinicalRoom() {
    return this.clinicalRoom;
  }
  
  public static List<QueueRealTimeResponse> build(List<QueueInstanceResponse> queueInstanceList, List<QueryQueuePatientListCountResponse> patientListCountList, List<InstancePositionInfoResponse> instancePositionList, List<ClinicalVisitInfoQueryResponse> clinicalVisitList, UserContext userContext) {
    List<QueueRealTimeResponse> responses = new ArrayList<>();
    Map<String, QueryQueuePatientListCountResponse> patientListCountMap = new HashMap<>();
    Map<String, List<InstancePositionInfoResponse>> instancePositionInfoListMap = new HashMap<>();
    Map<String, List<ClinicalVisitInfoQueryResponse>> clinicalVisitInfoListMap = new HashMap<>();
    if (CollectionUtils.isNotEmpty(patientListCountList))
      patientListCountMap = (Map<String, QueryQueuePatientListCountResponse>)patientListCountList.stream().collect(Collectors.toMap(QueryQueuePatientListCountResponse::getQueueInstanceId, v -> v)); 
    if (CollectionUtils.isNotEmpty(instancePositionList))
      instancePositionInfoListMap = (Map<String, List<InstancePositionInfoResponse>>)instancePositionList.stream().collect(Collectors.groupingBy(InstancePositionInfoResponse::getQueueInstanceId)); 
    if (CollectionUtils.isNotEmpty(clinicalVisitList))
      clinicalVisitInfoListMap = (Map<String, List<ClinicalVisitInfoQueryResponse>>)clinicalVisitList.stream().collect(Collectors.groupingBy(ClinicalVisitInfoQueryResponse::getQueueInstanceId)); 
    Map<String, QueryQueuePatientListCountResponse> finalPatientListCountMap = patientListCountMap;
    Map<String, List<InstancePositionInfoResponse>> finalInstancePositionInfoListMap = instancePositionInfoListMap;
    Map<String, List<ClinicalVisitInfoQueryResponse>> finalClinicalVisitInfoListMap = clinicalVisitInfoListMap;
    return (List<QueueRealTimeResponse>)queueInstanceList.stream().map(instance -> {
          QueryQueuePatientListCountResponse patientListCountInfo = (QueryQueuePatientListCountResponse)finalPatientListCountMap.get(instance.getQueueInstanceId());
          List<InstancePositionInfoResponse> instancePositionInfoList = (List<InstancePositionInfoResponse>)finalInstancePositionInfoListMap.get(instance.getQueueInstanceId());
          List<ClinicalVisitInfoQueryResponse> clinicalVisitInfoList = (List<ClinicalVisitInfoQueryResponse>)finalClinicalVisitInfoListMap.get(instance.getQueueInstanceId());
          return build(instance, patientListCountInfo, instancePositionInfoList, clinicalVisitInfoList, userContext);
        }).collect(Collectors.toList());
  }
  
  private static QueueRealTimeResponse build(QueueInstanceResponse instance, QueryQueuePatientListCountResponse patientListCountInfo, List<InstancePositionInfoResponse> instancePositionInfoList, List<ClinicalVisitInfoQueryResponse> clinicalVisitInfoList, UserContext userContext) {
    QueueRealTimeResponse resp = new QueueRealTimeResponse();
    List<QueueBasePatient> clinicalRoom = new ArrayList<>();
    BeanUtils.copyProperties(instance, resp);
    resp.setTriageDepartmentId(userContext.getIdDept());
    resp.setQueueRoomWaitingNumber(Integer.valueOf(0));
    if (ObjectUtils.isNotEmpty(patientListCountInfo))
      resp.setQueueRoomWaitingNumber(patientListCountInfo.getQueueRoomWaitingNumber()); 
    if (CollectionUtils.isNotEmpty(instancePositionInfoList))
      for (InstancePositionInfoResponse instancePositionInfo : instancePositionInfoList) {
        QueueBasePatient patientRoomInfo = new QueueBasePatient();
        patientRoomInfo.setClinicalRoomId(instancePositionInfo.getPositionId());
        patientRoomInfo.setClinicalRoomName(instancePositionInfo.getPositionName());
        if (CollectionUtils.isNotEmpty(clinicalVisitInfoList)) {
          List<ClinicalVisitInfoQueryResponse> visitList = (List<ClinicalVisitInfoQueryResponse>)clinicalVisitInfoList.stream().filter(c -> (StringUtils.isNotBlank(instancePositionInfo.getPositionId()) && c.getClinicalRoomDepartmentId().equals(instancePositionInfo.getPositionId()) && ObjectUtils.isNotEmpty(c.getCallTime()))).collect(Collectors.toList());
          if (CollectionUtils.isNotEmpty(visitList)) {
            visitList.sort(Comparator.<ClinicalVisitInfoQueryResponse, Comparable>comparing(ClinicalVisitInfoQueryResponse::getCallTime).reversed());
            patientRoomInfo.setPatientName(((ClinicalVisitInfoQueryResponse)visitList.get(0)).getPatientName());
            patientRoomInfo.setTicketNo(((ClinicalVisitInfoQueryResponse)visitList.get(0)).getTicketNo().toString());
          } 
        } 
        clinicalRoom.add(patientRoomInfo);
      }  
    resp.setClinicalRoom(clinicalRoom);
    return resp;
  }
}
